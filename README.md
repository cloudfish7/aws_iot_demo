# aws iot demo

##**Demo環境実行手順**

### **1.** s3bucketを作成する

### **2.** aws iot_demoをcloneする(Amazon Linux)
`git clone https://github.com/cloudfish7/aws_iot_demo.git`

### **3.** demo用環境構築
export AWS_ACCESS_KEY=XXXXXXXXXXXXXXX
export AWS_SECRET_KEY=YYYYYYYYYYYYYYYY
sh ./create_aws_iot_demo.sh aws_account_id s3_bucket_name`

### **4.** AWSIoTPythonSDKのインストール
`pip install AWSIoTPythonSDK` 

### **5.** サンプル実行
`python iotPublishDemo.py endpoint rootCA certificate privateKey`

