# aws iot demo

##**Demo環境実行手順**

### **1.** s3bucketを作成する

### **2.** Amazon Linuxを起動する

### **3.** aws iot_demoをダウンロードする
`git clone https://github.com/cloudfish7/aws_iot_demo.git`

### **4.** demo用環境構築
`sh ./create_aws_iot_demo.sh aws_account_id s3_bucket_name`

### **5.** AWSIoTPythonSDKのインストール
`pip install AWSIoTPythonSDK` 

### **6.** サンプル実行
`python iotPublishDemo.py endpoint rootCA certificate privateKey`

