if [ "$1" != "gaai-wd" ]; then
  echo "This script is not supposed to be run directly. Instead, start gaai.sh after configuring the user configurable variables within it"
else
  while true; do
    INPUT=$(tail -n1 gaai-sb.log)   # | tr -d '[' | tr -d ']')
    if [ "${INPUT}" != "" ]; then
      TEST=$(echo "${INPUT}" | grep -o "qps")
      if [ "${TEST}" == "qps" ]; then
        TEST=$(echo "${INPUT}" | grep -o "lat")
        if [ "${TEST}" == "lat" ]; then
          break
        fi
      fi
    fi
    sleep 0.05
  done
  QPS=$(echo ${INPUT} | sed 's|.*qps: ||;s| (r/w/o:.*||')
  TIME=$(echo ${INPUT} | sed 's|^..||;s|s . thds.*||')
  echo ${QPS} > gaai.qps
  echo ${TIME} > gaai.time
fi
