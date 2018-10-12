while true; do
  INPUT=$(tail -n1 gaai-sb.log)
  if [[ "$INPUT" == *"qps:"* ]]; then
    if [[ "$INPUT" == *"(r/w/o:"* ]]; then
      break
    fi
  fi
  sleep 0.05
done
OUTPUT=$(echo ${INPUT} sed 's|.*qps: ||;s| (r/w/o.*)||'
echo OUTPUT > gaai.qps
sleep 0.20
