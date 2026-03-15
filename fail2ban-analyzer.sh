#!/bin/bash

# ================= 配置区 =================
DB_DIR="/usr/local/bin"
DB_CITY="$DB_DIR/GeoLite2-City.mmdb"
DB_ASN="$DB_DIR/GeoLite2-ASN.mmdb"
LOG_FILE="/var/log/fail2ban-analysis.log"

# GitHub 原始链接 (指向 download 分支，确保获取最新版)
URL_CITY="https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb"
URL_ASN="https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-ASN.mmdb"
# ==========================================

# 数据库自动更新逻辑
update_db() {
    local needs_update=false
    # 如果文件不存在或修改时间超过 15 天则更新
    if [ ! -f "$DB_CITY" ] || [ ! -f "$DB_ASN" ]; then
        needs_update=true
    elif [ $(( ( $(date +%s) - $(stat -c %Y "$DB_CITY") ) / 86400 )) -ge 15 ]; then
        needs_update=true
    fi

    if [ "$needs_update" = true ]; then
        echo "[$(date)] 正在从 GitHub 更新 GeoLite2 数据库..."
        # 使用 -N 选项，仅在服务器文件较旧时下载
        wget -q -O "$DB_CITY" "$URL_CITY"
        wget -q -O "$DB_ASN" "$URL_ASN"
        echo "[$(date)] 数据库更新完成。"
    fi
}

run_analysis() {
    update_db

    # 1. 动态获取所有 Jail (包含 recidive, sshd 等)
    JAILS=$(fail2ban-client status | grep "Jail list:" | sed 's/.*Jail list://; s/,//g')
    
    RAW_IPS=""
    for jail in $JAILS; do
        # 提取并清理格式符号，确保只拿到纯 IP
        IPS=$(fail2ban-client status "$jail" | grep "Banned IP list:" | sed 's/.*Banned IP list://' | tr -d '|`-' | tr ' ' '\n')
        RAW_IPS="${RAW_IPS} ${IPS}"
    done
    
    # 提取唯一的 IPv4 地址
    ALL_IPS=$(echo "$RAW_IPS" | tr ' ' '\n' | grep -P '^(\d{1,3}\.){3}\d{1,3}$' | sort -u)

    if [ -z "$ALL_IPS" ]; then
        echo "当前无封禁记录。" > "$LOG_FILE"
        return
    fi

    REPORT="==================== Fail2banIP监控分析 (GeoLite2) ====================
分析时间: $(date)
监测范围: $(echo $JAILS | tr ' ' ',')
--------------------------------------------------------------------------------
$(printf "%-18s | %-12s | %-12s | %-12s | %-15s\n" "IP地址" "国家" "城市" "运营商")
--------------------------------------------------------------------------------"

# 计算总数
    TOTAL_IPS=$(echo "$ALL_IPS" | wc -l)
    CURRENT=0

    echo "正在开始分析 $TOTAL_IPS 个 IP 地址..."

    for ip in $ALL_IPS; do
        # --- 进度条逻辑 ---
        ((CURRENT++))
        PERCENT=$(( CURRENT * 100 / TOTAL_IPS ))
        # 生成进度条视觉效果 [#####     ]
        BAR_WIDTH=30
        FILLED=$(( PERCENT * BAR_WIDTH / 100 ))
        EMPTY=$(( BAR_WIDTH - FILLED ))
        BAR=$(printf "%${FILLED}s" | tr ' ' '#')$(printf "%${EMPTY}s" | tr ' ' '-')
        
        # 使用 \r 让输出回到行首，不换行显示实时进度
        printf "\r进度: [%s] %d%% (%d/%d) 正在查询: %-15s" "$BAR" "$PERCENT" "$CURRENT" "$TOTAL_IPS" "$ip"

        # --- 原有的查询逻辑 ---
        # 1. 获取国家
        COUNTRY=$(mmdblookup --file "$DB_CITY" --ip "$ip" country names en 2>/dev/null | grep 'utf8_string' | head -n 1 | awk -F'"' '{print $2}')
        [ -z "$COUNTRY" ] && COUNTRY=$(mmdblookup --file "$DB_CITY" --ip "$ip" registered_country names en 2>/dev/null | grep 'utf8_string' | head -n 1 | awk -F'"' '{print $2}')

        # 2. 获取城市 (带省份回退)
        CITY=$(mmdblookup --file "$DB_CITY" --ip "$ip" city names en 2>/dev/null | grep 'utf8_string' | head -n 1 | awk -F'"' '{print $2}')
        if [ -z "$CITY" ]; then
            CITY=$(mmdblookup --file "$DB_CITY" --ip "$ip" subdivisions 0 names en 2>/dev/null | grep 'utf8_string' | head -n 1 | awk -F'"' '{print $2}')
        fi

        # 3. 获取运营商 (ASN)
        ISP_VAL=$(mmdblookup --file "$DB_ASN" --ip "$ip" autonomous_system_organization 2>/dev/null | grep 'utf8_string' | head -n 1 | awk -F'"' '{print $2}')
        [ -z "$ISP_VAL" ] && ISP_VAL=$(mmdblookup --file "$DB_ASN" --ip "$ip" organization 2>/dev/null | grep 'utf8_string' | head -n 1 | awk -F'"' '{print $2}')
        
        # 4. 变量清理
        COUNTRY=${COUNTRY:-"Unknown"}
        CITY=${CITY:-"Unknown"}
        ISP_VAL=${ISP_VAL:-"Unknown"}

        # 5. 写入报告变量 (不输出到屏幕，保持屏幕整洁)
        LINE=$(printf "%-18s | %-16s | %-20s | %-s" "$ip" "$COUNTRY" "$CITY" "$ISP_VAL")
        REPORT="${REPORT}\n${LINE}"
    done

    # 循环结束后换行，并提示完成
    echo -e "\n[$(date)] 分析完成！结果已写入 $LOG_FILE，请通过命令 cat $LOG_FILE 查询"

    echo -e "${REPORT}\n--------------------------------------------------------------------------------" > "$LOG_FILE"
}

run_analysis