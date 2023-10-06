#!/bin/bash

# Author           : Adam Pacek ( adam@pacek.it )
# Created On       : 3.06.2023
# Last Modified By : Adam Pacek ( adam@pacek.it )
# Last Modified On : 3.06.2023
# Version          : 1.0
#
# Description      : Script that analyses GPX file. -h for help.
# Opis			   : Skrypt analizujący plik GPX. -h by wyświetlić pomoc.
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

print_help() {
  echo "Skrypt analizujący plik GPX"
  echo
  echo "Opcje:"
  echo "  -v      Wyświetla informacje o wersji"
  echo "  -h      Wyświetla pomoc"
  echo
  echo "Funkcjonalności:"
  echo "  -l Oblicza długość trasy"
  echo "  -t Oblicza czas trwania"
  echo "  -a Oblicza średnią prędkość"
  echo "  -r Oblicza średni puls"
  echo "  -x Znajduje maksymalną prędkość"
  echo "  -m Znajduje maksymalny puls"
  echo  
  echo "Sposób użycia:" 
  echo "./a.sh [-v] [-h] [-l] [-t] [-a] [-r] [-x] [-m] nazwa_pliku.gpx"
  echo
  exit 0
}

print_version() {
  echo "Wersja 1.0"
  echo "Autor: Adam Pacek"
  echo "Data wydania: 3.06.2023"
  
  exit 0
}

calculate_distance() {

  lat_tab=$(grep -oP '<trkpt lat="\K[^"]+' "$gpx_file")
  lon_tab=$(grep -oP 'lon="\K[^"]+' "$gpx_file")

  mapfile -t lat_lines <<< "$lat_tab"
  mapfile -t lon_lines <<< "$lon_tab"

  distance=0.0
  prev_lat=0
  prev_lon=0

  deg_to_meter_factor=111120

  for ((i=0; i<${#lat_lines[@]}; i++)); do
    lat=${lat_lines[i]}
    lon=${lon_lines[i]}

    if [[ $prev_lat != 0 && $prev_lon != 0 ]]; then
      delta_lat=$(bc -l <<< "$lat - $prev_lat")
      delta_lon=$(bc -l <<< "$lon - $prev_lon")

      lat_distance=$(bc -l <<< "$delta_lat * $deg_to_meter_factor")
      lon_distance=$(bc -l <<< "$delta_lon * $deg_to_meter_factor * 0.58778525229")

      segment_distance=$(bc -l <<< "sqrt($lat_distance^2 + $lon_distance^2)")
      distance=$(bc -l <<< "$distance + $segment_distance")
    fi

    prev_lat="$lat"
    prev_lon="$lon"
  done

  echo "Długość trasy: $distance m"
}

calculate_duration() {

  time_list=$(grep -oP '<time>\K.*(?=</time>)' "$gpx_file")

  start_time=$(echo "$time_list" | head -n 1)
  end_time=$(echo "$time_list" | tail -n 1)

  start_timestamp=$(date -d "$start_time" +%s)
  end_timestamp=$(date -d "$end_time" +%s)
  duration=$((end_timestamp - start_timestamp))

  duration_formatted=$(date -u -d @"$duration" +%H:%M:%S)
  echo "Czas trwania trasy: $duration_formatted"
}

calculate_average_speed() {
  time_list=$(grep -oP '<time>\K.*(?=</time>)' "$gpx_file")

  start_time=$(echo "$time_list" | head -n 1)
  end_time=$(echo "$time_list" | tail -n 1)

  start_timestamp=$(date -d "$start_time" +%s)
  end_timestamp=$(date -d "$end_time" +%s)
  duration=$((end_timestamp - start_timestamp))
  
  lat_tab=$(grep -oP '<trkpt lat="\K[^"]+' "$gpx_file")
  lon_tab=$(grep -oP 'lon="\K[^"]+' "$gpx_file")

  mapfile -t lat_lines <<< "$lat_tab"
  mapfile -t lon_lines <<< "$lon_tab"

  distance=0.0
  prev_lat=0
  prev_lon=0

  deg_to_meter_factor=111120

  for ((i=0; i<${#lat_lines[@]}; i++)); do
    lat=${lat_lines[i]}
    lon=${lon_lines[i]}

    if [[ $prev_lat != 0 && $prev_lon != 0 ]]; then
      delta_lat=$(bc -l <<< "$lat - $prev_lat")
      delta_lon=$(bc -l <<< "$lon - $prev_lon")

      lat_distance=$(bc -l <<< "$delta_lat * $deg_to_meter_factor")
      lon_distance=$(bc -l <<< "$delta_lon * $deg_to_meter_factor * 0.58778525229")

      segment_distance=$(bc -l <<< "sqrt($lat_distance^2 + $lon_distance^2)")
      distance=$(bc -l <<< "$distance + $segment_distance")
    fi

    prev_lat="$lat"
    prev_lon="$lon"
  done
  
  average_speed=$(bc -l <<< "$distance / $duration")

  echo "Średnia prędkość: $average_speed m/s"
  
}

calculate_average_heart_rate() {
  heart_rate_list=$(grep -Eo '<gpxtpx:hr>[0-9]+' "$gpx_file" | sed 's/<gpxtpx:hr>//')

  avg_heart_rate=0
  counter=0

for heart_rate in $heart_rate_list; do
  avg_heart_rate=$((avg_heart_rate + heart_rate))
  counter=$((counter + 1))
done

  echo "Średni puls: $((avg_heart_rate / counter))"
}

find_max_speed() {
  
  lat_tab=$(grep -oP '<trkpt lat="\K[^"]+' "$gpx_file")
  lon_tab=$(grep -oP 'lon="\K[^"]+' "$gpx_file")

  mapfile -t lat_lines <<< "$lat_tab"
  mapfile -t lon_lines <<< "$lon_tab"

  prev_lat=0
  prev_lon=0
  max_speed=0
  segment_time=1

  deg_to_meter_factor=111120

  for ((i=0; i<${#lat_lines[@]}; i++)); do
    lat=${lat_lines[i]}
    lon=${lon_lines[i]}

    if [[ $prev_lat != 0 && $prev_lon != 0 ]]; then
      delta_lat=$(bc -l <<< "$lat - $prev_lat")
      delta_lon=$(bc -l <<< "$lon - $prev_lon")

      lat_distance=$(bc -l <<< "$delta_lat * $deg_to_meter_factor")
      lon_distance=$(bc -l <<< "$delta_lon * $deg_to_meter_factor * 0.58778525229")

      segment_distance=$(bc -l <<< "sqrt($lat_distance^2 + $lon_distance^2)")
	  segment_speed=$(bc -l <<< "$segment_distance / $segment_time")
	if (( $(bc -l <<< "$segment_speed > $max_speed") )); then
      max_speed=$segment_speed
    fi
	  
    fi

    prev_lat="$lat"
    prev_lon="$lon"
  done

  echo "Maksymalna prędkość: $max_speed m/s"
}

find_max_heart_rate() {

  heart_rate_list=$(grep -Eo '<gpxtpx:hr>[0-9]+' "$gpx_file" | sed 's/<gpxtpx:hr>//')

  max_heart_rate=0

  for heart_rate in $heart_rate_list; do
    if [ "$heart_rate" -gt "$max_heart_rate" ]; then
      max_heart_rate="$heart_rate"
    fi
  done

  echo "Maksymalny puls: $max_heart_rate"
}

calculate_distance=false
calculate_duration=false
calculate_average_speed=false
calculate_average_heart_rate=false
find_max_speed=false
find_max_heart_rate=false


while getopts "vhltarxm" option; do
  case $option in
    v)
      print_version
      ;;
    h)
      print_help
      ;;
    l)
      calculate_distance=true
      ;;
    t)
      calculate_duration=true
      ;;
    a)
      calculate_average_speed=true
      ;;
    r)
      calculate_average_heart_rate=true
      ;;
    x)
      find_max_speed=true
      ;;
    m)
      find_max_heart_rate=true
      ;;
    *)
      print_help
      ;;
  esac
done

shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
  echo "Błąd: Nie podano pliku GPX."
  print_help
fi

gpx_file="${!#}"

if [ "$calculate_duration" = true ]; then
  calculate_duration "$gpx_file"
fi

if [ "$calculate_distance" = true ]; then
  calculate_distance "$gpx_file"
fi

if [ "$calculate_average_speed" = true ]; then
  calculate_average_speed "$gpx_file"
fi

if [ "$find_max_speed" = true ]; then
  find_max_speed "$gpx_file"
fi

if [ "$calculate_average_heart_rate" = true ]; then
  calculate_average_heart_rate "$gpx_file"
fi

if [ "$find_max_heart_rate" = true ]; then
  find_max_heart_rate "$gpx_file"
fi
