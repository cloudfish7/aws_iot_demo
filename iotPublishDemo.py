from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient
import sys
import logging
import time
import getopt


argvs = sys.argv

# Read in command-line parameters
host = argvs[1]
rootCAPath = argvs[2]
certificatePath = argvs[3]
privateKeyPath = argvs[4]

# Configure logging
logger = logging.getLogger("AWSIoTPythonSDK.core") 
logger.setLevel(logging.DEBUG)
streamHandler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
streamHandler.setFormatter(formatter)
logger.addHandler(streamHandler)

# Configure Conncect Setting
myAWSIoTMQTTClient = AWSIoTMQTTClient("basicPubSub")
myAWSIoTMQTTClient.configureEndpoint(host, 8883)
myAWSIoTMQTTClient.configureCredentials(rootCAPath, privateKeyPath, certificatePath)

# AWSIoTMQTTClient connection configuration
myAWSIoTMQTTClient.configureAutoReconnectBackoffTime(1, 32, 20)
myAWSIoTMQTTClient.configureOfflinePublishQueueing(-1)  
myAWSIoTMQTTClient.configureDrainingFrequency(2)  
myAWSIoTMQTTClient.configureConnectDisconnectTimeout(10)  
myAWSIoTMQTTClient.configureMQTTOperationTimeout(5)  

# Connect and subscribe to AWS IoT
myAWSIoTMQTTClient.connect()

# Publish to the same topic in a loop forever
loopCount = 0
while True:
	myAWSIoTMQTTClient.publish("iot_device", "Message " + str(loopCount), 1)
	loopCount += 1
	time.sleep(1)

