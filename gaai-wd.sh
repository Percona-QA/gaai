if [ "$1" != "gaai-wd" ]; then
  echo "This script is not supposed to be run directly. Instead, start gaai.sh after configuring the user configurable variables within it"
else
  while true; do 
    while true; do
      INPUT=$(tail -n1 gaai-sb.log)
      if [ "${INPUT}" != "" ]; then 
        if [[ "${INPUT}" == *"qps:"* ]]; then
          if [[ "${INPUT}" == *"(r/w/o:"* ]]; then
            break
          fi
        fi
      fi
      sleep 0.05
    done
    QPS=$(echo ${INPUT} | sed 's|.*qps: ||;s| (r/w/o:.*||')
    echo ${QPS} > gaai.qps
    sleep 0.20
  done
fi
