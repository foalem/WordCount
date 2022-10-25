#!/bin/bash

sudo apt update -y
sudo apt install default-jdk -y
echo "export JAVA_HOME=/usr/lib/jvm/default-java" | sudo tee -a .profile >/dev/null
echo "export HADOOP_HOME=/usr/local/hadoop-3.3.4" | sudo tee -a .profile >/dev/null
echo "export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin" | sudo tee -a .profile >/dev/null
source .profile
sudo curl -O https://dlcdn.apache.org/hadoop/common/stable/hadoop-3.3.4.tar.gz
sudo tar -xf hadoop-3.3.4.tar.gz -C /usr/local/
echo "export JAVA_HOME=/usr/lib/jvm/default-java" | sudo tee -a /usr/local/hadoop-3.3.4/etc/hadoop/hadoop-env.sh >/dev/null
echo "export HADOOP_HOME=/usr/local/hadoop-3.3.4" | sudo tee -a /usr/local/hadoop-3.3.4/etc/hadoop/hadoop-env.sh >/dev/null
hadoop com.sun.tools.javac.Main WordCount.java
sudo jar cf wc.jar WordCount*.class
hdfs dfs -mkdir input
sudo curl -LO --compressed http://www.gutenberg.org/cache/epub/4300/pg4300.txt
hdfs dfs -copyFromLocal pg4300.txt input
time hadoop jar wc.jar WordCount input output
time cat pg4300.txt | tr -c "[:graph:]" "\n" | sort | uniq -c
