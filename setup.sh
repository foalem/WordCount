#!/bin/bash

echo "Installing dependencies..."
sudo apt-get update -y >/dev/null
sudo apt-get install default-jdk -y >/dev/null
echo "Done."

echo "Setting environment variables for java, hadoop and spark..."
echo "export JAVA_HOME=/usr/lib/jvm/default-java" | sudo tee -a .profile >/dev/null
echo "export HADOOP_HOME=/usr/local/hadoop-3.3.4" | sudo tee -a .profile >/dev/null
echo "export SPARK_HOME=/usr/local/spark-2.0.0-bin-hadoop2.7" | sudo tee -a .profile >/dev/null
echo "export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$SPARK_HOME/bin" | sudo tee -a .profile >/dev/null
source .profile
echo "Done."

echo "Downloading Hadoop-3.3.4..."
sudo curl -O https://dlcdn.apache.org/hadoop/common/stable/hadoop-3.3.4.tar.gz 2>/dev/null
echo "Done."

echo "Downloading Spark-2.0.0..."
sudo curl -O https://archive.apache.org/dist/spark/spark-2.0.0/spark-2.0.0-bin-hadoop2.7.tgz 2>/dev/null
echo "Done."

echo "Installing Hadoop-3.3.4..."
sudo tar -xf hadoop-3.3.4.tar.gz -C /usr/local/
echo "Done."

echo "Installing Spark-2.0.0..."
sudo tar -xf spark-2.0.0-bin-hadoop2.7.tgz -C /usr/local/
echo "Done."

echo "Setting specific environment variables for hadoop..."
echo "export JAVA_HOME=/usr/lib/jvm/default-java" | sudo tee -a /usr/local/hadoop-3.3.4/etc/hadoop/hadoop-env.sh >/dev/null
echo "export HADOOP_HOME=/usr/local/hadoop-3.3.4" | sudo tee -a /usr/local/hadoop-3.3.4/etc/hadoop/hadoop-env.sh >/dev/null
echo "Done."

echo "Compiling WordCount.java..."
hadoop com.sun.tools.javac.Main WordCount.java
sudo jar cf wc.jar WordCount*.class
echo "Done."

echo "Creating input directory..."
hdfs dfs -mkdir input
echo "Done."

echo "Creating data directory..."
mkdir data
echo "Done."

echo "Downloading datasets..."
sudo curl -L --compressed http://www.gutenberg.org/cache/epub/4300/pg4300.txt -o data/pg4300.txt 2>/dev/null
sudo curl -L --compressed http://www.gutenberg.ca/ebooks/buchanj-midwinter/buchanj-midwinter-00-t.txt -o data/buchanj-midwinter-00-t.txt 2>/dev/null
sudo curl -L --compressed http://www.gutenberg.ca/ebooks/carman-farhorizons/carman-farhorizons-00-t.txt -o data/carman-farhorizons-00-t.txt 2>/dev/null
sudo curl -L --compressed http://www.gutenberg.ca/ebooks/colby-champlain/colby-champlain-00-t.txt -o data/colby-champlain-00-t.txt 2>/dev/null
sudo curl -L --compressed http://www.gutenberg.ca/ebooks/cheyneyp-darkbahama/cheyneyp-darkbahama-00-t.txt -o data/cheyneyp-darkbahama-00-t.txt 2>/dev/null
sudo curl -L --compressed http://www.gutenberg.ca/ebooks/delamare-bumps/delamare-bumps-00-t.txt -o data/delamare-bumps-00-t.txt 2>/dev/null
sudo curl -L --compressed http://www.gutenberg.ca/ebooks/charlesworth-scene/charlesworth-scene-00-t.txt -o data/charlesworth-scene-00-t.txt 2>/dev/null
sudo curl -L --compressed http://www.gutenberg.ca/ebooks/delamare-lucy/delamare-lucy-00-t.txt -o data/delamare-lucy-00-t.txt 2>/dev/null
sudo curl -L --compressed http://www.gutenberg.ca/ebooks/delamare-myfanwy/delamare-myfanwy-00-t.txt -o data/delamare-myfanwy-00-t.txt 2>/dev/null
sudo curl -L --compressed http://www.gutenberg.ca/ebooks/delamare-penny/delamare-penny-00-t.txt -o data/delamare-penny-00-t.txt 2>/dev/null
echo "Done."

echo "Copying datasets from data to input directory..."
hdfs dfs -copyFromLocal data/* input
echo "Done."

echo "Creating time.txt file..."
touch time_linux.txt
touch time_hadoop.txt
touch time_hadoop_vs_linux.txt
touch time_spark.txt
echo "Done."

echo "Running WordCount on Hadoop vs Linux..."
printf "############################################\n"  >/dev/null
printf "WordCount execution time on Hadoop vs Linux\n" >/dev/null
printf "############################################\n"  >/dev/null
printf -- "--------------------------------------------\n"  >/dev/null
printf "Hadoop:\n"  >/dev/null
printf -- "--------------------------------------------"  >/dev/null
(time (hadoop jar wc.jar WordCount ./input/pg4300.txt output &>/dev/null)) &>> time_hadoop_vs_linux.txt
printf -- "--------------------------------------------\n"  >/dev/null
printf "Linux:\n"  >/dev/null
printf -- "--------------------------------------------\n"  >/dev/null
(time (cat ./input/pg4300.txt | tr -c "[:graph:]" "\n" | sort | uniq -c &>/dev/null)) &>> time_linux.txt
echo "Done."


echo "Running WordCount on Hadoop..."
printf "############################################\n"  >/dev/null
printf "WordCount execution time on Hadoop\n"  >/dev/null
printf "############################################\n"  >/dev/null
for ((i = 1; i <= 3; i++)); do
    echo "Running test #$i..."
    printf -- "*******************\n"  >/dev/null
    printf "Test: #%s\n" "$i" >/dev/null
    printf -- "*******************\n"  >/dev/null
    for dataset in ./input/*.txt; do
        hdfs dfs -rm -r output &>/dev/null
        printf -- "--------------------------------------------\n"  >/dev/null
        printf "%s" "$dataset" | sudo tee -a time_hadoop.txt >/dev/null
        printf -- "--------------------------------------------" >/dev/null
        (time (hadoop jar wc.jar WordCount "$dataset" output &>/dev/null)) &>> time_hadoop.txt
    done
done
echo "Done."

echo "Running WordCount on Spark..."
printf "############################################\n"  >/dev/null
printf "WordCount execution time on Spark\n" >/dev/null
printf "############################################\n"  >/dev/null
for ((i = 1; i <= 3; i++)); do
    echo "Running test #$i..."
    printf -- "*******************\n"  >/dev/null
    printf "Test: #%s\n" "$i"  >/dev/null
    printf -- "*******************\n"  >/dev/null
    for dataset in ./input/*.txt; do
        hdfs dfs -rm -r output &>/dev/null
        printf -- "--------------------------------------------\n"  >/dev/null
        printf "%s\n" "$dataset" | sudo tee -a time_spark.txt >/dev/null
        printf -- "--------------------------------------------"  >/dev/null
        (time (spark\-submit --class WordCount wc.jar "$dataset" output &>/dev/null)) &>> time_spark.txt
    done
done
echo "Done."

echo "Execution time successfully saved"

