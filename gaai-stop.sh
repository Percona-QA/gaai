ps -ef | grep './gaai-sb' | grep -v grep | grep bash | awk '{print $2}' | xargs kill -9
