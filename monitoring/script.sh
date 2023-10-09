#!/bin/bash

print_cpu_cores() {
  # Распечатать количество ядер CPU
  local cores="$(nproc)"
  echo "Количество ядер процессора: $cores"
}

print_mem_MB() {
  # Распечатать информацию о ОЗУ:
  # * объём оперативной памяти в системе;
  # * количество использованной оперативной памяти.
  local mem_info_KB="$(cat /proc/meminfo | grep -E 'MemTotal|MemFree')"
  local total_mem_KB=$(echo "$mem_info_KB" | awk '/^MemTotal/ {print $2}')
  local free_mem_KB=$(echo "$mem_info_KB" | awk '/^MemFree/ {print $2}')
  local used_mem_KB=$(($total_mem_KB-$free_mem_KB))
  echo "Объём оперативной памяти в системе: $(($total_mem_KB/1024)) MB"
  echo "Объём используемой оперативной памяти: $(($used_mem_KB/1024)) MB"
}

print_disks() {
  # Распечатать информацию о дисках:
  # * какие диски есть в системе;
  # * размер диска;
  # * свободное пространство на диске (в процентах);
  # * количество ошибок.
  while IFS= read -r line
  do
    local disk_name=$(echo "$line" | awk '{print $1}')
    local disk_size=$(echo "$line" | awk '{print $4}')
    # TODO: Не понятно как считать свободное пространство на диске (в процентах)
    # Т.к. диск sda может принадлежать lvm, а lvm состоять из нескольких дисков.
    # local disk_free_size_percents=
    
    # TODO: Не понятно как считать количество ошибок.
    # local disk_sectors_discarded=$(cat /proc/diskstats | grep -E "$disk_name " | awk '{print $17}')
    echo "Имя диска: $disk_name, Размер диска: $disk_size"
  done <<< $(lsblk | grep -E 'sd[a-z] ')
}

print_load_average() {
  # Распечатать среднюю загрузку системы (load average).
  local load_average_info=$(cat /proc/loadavg)
  local loadavg_1min=$(echo "$load_average_info" | awk '{print $1}')
  local loadavg_5min=$(echo "$load_average_info" | awk '{print $2}')
  local loadavg_15min=$(echo "$load_average_info" | awk '{print $3}')
  echo "Загрузка системы за 1 минуту: $loadavg_1min"
  echo "Загрузка системы за 5 минуту: $loadavg_5min"
  echo "Загрузка системы за 15 минуту: $loadavg_15min"
}

print_local_time() {
  # Распечатать текущее время в системе.
  local local_time=$(date)
  echo "Время хоста: $local_time"
}

print_uptime() {
  # Распечатать время работы системы.
  local uptime_total_sec=$(cat /proc/uptime | awk '{print $1}')
  local uptime_hours=$(echo "$uptime_total_sec / 3600" | bc)
  local uptime_minutes=$(echo "$uptime_total_sec / 60 - $uptime_hours * 60" | bc)
  echo "Время работы системы: $uptime_hours:$uptime_minutes h:m"
}

print_net_interfaces() {
  # Распечатать сетевые интерфейсы:
  # * какие есть в системе;
  # * их статус;
  # * IP-адрес;
  # * количество отправленных и полученных пакетов;
  # * количество ошибок на интерфейсе.
  while IFS= read -r line
  do
    local interface_name=$(echo "$line" | tr ':' ' ' | awk '{print $1}')
    local interface_status=$(ip --brief address show $interface_name | awk '{print $2}')
    local interface_ipv4_address=$(ip -br -4 address show $interface_name | awk '{print $3}')
    local interface_receive_packets=$(echo "$line" | tr ':' ' ' | awk '{print $3}')
    local interface_receive_err_packets=$(echo "$line" | tr ':' ' ' | awk '{print $4}')
    local interface_send_packets=$(echo "$line" | tr ':' ' ' | awk '{print $11}')
    local interface_send_err_packets=$(echo "$line" | tr ':' ' ' | awk '{print $12}')

    echo "Данные для интерфейса: $interface_name"
    echo "  Статус интерфейса: $interface_status"
    echo "  Адреса интерфейса: $interface_ipv4_address"
    echo "  Кол-во полученных пакетов всего: $interface_receive_packets"
    echo "  Кол-во полученных пакетов с ошибками: $interface_receive_err_packets"
    echo "  Кол-во отправденных пакетов всего: $interface_send_packets"
    echo "  Кол-во отправденных пакетов с ошибками: $interface_send_err_packets"
  done <<< $(tail -n +3 /proc/net/dev)
}

print_ports() {
  # Распечатать порты, которые слушаются на системе.
  echo "Занятые порты:" 
  while IFS= read -r line
  do
    if [[ $line == "COMMAND"* || $line == *"LISTEN"* ]]; then
      echo "  $line"
    fi
  done <<< $(lsof -i -P -n)
}

show_host() {
  echo "Информация о хосте:"
  print_cpu_cores
  print_mem_MB
  print_disks
  print_load_average
  print_local_time
  print_uptime
  print_net_interfaces
  print_ports
}

print_users() {
  # Распечатать список пользователей в системе.
  echo "Cписок пользователей в системе:" 
  while IFS= read -r line
  do
    local user=$(echo "$line" | awk -F':' '{print $1}')
    local uid=$(echo "$line" | awk -F':' '{print $3}')
    local gid=$(echo "$line" | awk -F':' '{print $4}')

    echo "  Пользователь: $user"
    echo "    UID: $uid"
    echo "    GID: $gid"
  done <<< $(cat /etc/passwd)
}

print_root_users() {
  # Распечатать список root-пользователей в системе.
  echo "Cписок root-пользователей в системе:" 
  while IFS= read -r line
  do
    local user=$(echo "$line" | awk -F':' '{print $1}')
    local uid=$(echo "$line" | awk -F':' '{print $3}')
    local gid=$(echo "$line" | awk -F':' '{print $4}')
    
    if [[ $uid -eq 0 ]]; then
      echo "  root-пользователей: $user"
      echo "    UID: $uid"
      echo "    GID: $gid"
    fi
  done <<< $(cat /etc/passwd)
}

print_login_users() {
  # Распечатать список залогиненных пользователей в момент запуска скрипта.
  echo "Cписок алогиненных пользователей в момент запуска скрипта:" 
  while IFS= read -r line
  do
    local user=$(echo "$line" | awk '{print $1}')
    local terminal=$(echo "$line" | awk '{print $2}')
    local ip=$(echo "$line" | awk '{print $5}')
    
    if [[ $uid -eq 0 ]]; then
      echo "  Подключенный пользователь: $user"
      echo "    terminal: $terminal"
      echo "    ip: $ip"
    fi
  done <<< $(who)
}

show_user() {
  echo "Информация о пользователях системы:"
  print_users
  print_root_users
  print_login_users

}

show_help() {
  echo "Использование: script.sh [опции]"
  echo "Опции:"
  echo "  --host     информацию о хосте;"
  echo "  --user     информацию о пользователях;"
  echo "  --help     информацию о том, какие параметры поддерживает скрипт."
}

OPTIONS=$(getopt -o -l "host,user,help:" -- "$@")

if [[ $# -eq 0 ]]; then
  show_help
  exit 0
fi

while true; do
  case "$1" in
    --host)
      show_host
      shift ;;
    --user)
      show_user
      shift ;;
    --help)
      show_help
      exit 0 ;;
    --)
      shift
      break ;;
    *)
      echo "Подерживается только следующие аргумнты: --host, --user, --help."
      echo "Полученные аргументы при вызове скрипта: $* не поддерживаются."
      exit 1 ;;
  esac
done
