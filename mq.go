// Package amqp contains AMQP API for a remote server.
package mq

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/ibm-messaging/mq-golang/v5/ibmmq"
	log "github.com/sirupsen/logrus"
	"go.k6.io/k6/js/modules"
)

const version = "v0.1.0"

// MQ type holds connection to a remote MQ Broker.
type MQ struct {
	mqHost     string
	mqPort     int
	mqChannel  string
	qMgrName   string
	qName      string
	qMgrObject *ibmmq.MQQueueManager
	qObject    *ibmmq.MQObject
}

// Options defines configuration options for a MQ Connection.
// Start establishes a session with a MQ Broker given the provided options.
func (mq *MQ) Start() error {
	os.Setenv("MQSERVER", fmt.Sprintf("%s/TCP/%s(%d)", mq.mqChannel, mq.mqHost, mq.mqPort))
	os.Setenv("MQ_CONNECT_TYPE", "Client")
	log.Info(fmt.Sprintf("MQ Host set to %s", os.Getenv("MQSERVER")))
	log.Info(fmt.Sprintf("Connecting to Queue %s on qmgr %s.", mq.qName, mq.qMgrName))

	// Allocate the MQCNO and MQCD structures needed for the CONNX call.
	cno := ibmmq.NewMQCNO()
	cd := ibmmq.NewMQCD()

	cd.ChannelName = mq.mqChannel
	cd.ConnectionName = fmt.Sprintf("%s(%d)", mq.mqHost, mq.mqPort)

	cno.ClientConn = cd
	cno.Options = ibmmq.MQCNO_CLIENT_BINDING

	cno.ApplName = "xk6-mq"

	csp := ibmmq.NewMQCSP()
	csp.AuthenticationType = ibmmq.MQCSP_AUTH_USER_ID_AND_PWD
	csp.UserId = "app"
	csp.Password = "passw0rd"

	cno.SecurityParms = csp

	b, err := json.Marshal(cno)
	if err != nil {
		return err
	}

	log.Info(string(b))

	qMgrObject, err := ibmmq.Connx(mq.qMgrName, cno)
	mq.qMgrObject = &qMgrObject

	if err != nil {
		return err
	}

	// Open the queue
	// Create the Object Descriptor that allows us to give the queue name
	mqod := ibmmq.NewMQOD()

	// We have to say how we are going to use this queue. In this case, to PUT
	// messages. That is done in the openOptions parameter.
	openOptions := ibmmq.MQOO_OUTPUT

	// Opening a QUEUE (rather than a Topic or other object type) and give the name
	mqod.ObjectType = ibmmq.MQOT_Q
	mqod.ObjectName = mq.qName

	queueObj, err := qMgrObject.Open(mqod, openOptions)
	mq.qObject = &queueObj

	return err
}

// Publish delivers the payload using options provided.
func (mq *MQ) Putter(fileName string) error {
	log.Info("mq put")

	// The PUT requires control structures, the Message Descriptor (MQMD)
	// and Put Options (MQPMO). Create those with default values.
	putmqmd := ibmmq.NewMQMD()
	pmo := ibmmq.NewMQPMO()

	// The default options are OK, but it's always
	// a good idea to be explicit about transactional boundaries as
	// not all platforms behave the same way.
	pmo.Options = ibmmq.MQPMO_NO_SYNCPOINT

	// The message is always sent as bytes, so has to be converted before the PUT.
	buffer, err := os.ReadFile(fileName)

	if err != nil {
		return err
	}

	// Now put the message to the queue
	err = mq.qObject.Put(putmqmd, pmo, buffer)

	return err
}

// Publish delivers the payload using options provided.
func (mq *MQ) Put() error {
	log.Info("mq put")

	// The PUT requires control structures, the Message Descriptor (MQMD)
	// and Put Options (MQPMO). Create those with default values.
	putmqmd := ibmmq.NewMQMD()
	pmo := ibmmq.NewMQPMO()

	// The default options are OK, but it's always
	// a good idea to be explicit about transactional boundaries as
	// not all platforms behave the same way.
	pmo.Options = ibmmq.MQPMO_NO_SYNCPOINT

	// Tell MQ what the message body format is. In this case, a text string
	putmqmd.Format = ibmmq.MQFMT_STRING

	// And create the contents to include a timestamp just to prove when it was created
	msgData := "Hello from Go at " + time.Now().Format(time.RFC3339)

	// The message is always sent as bytes, so has to be converted before the PUT.
	buffer := []byte(msgData)

	// Now put the message to the queue
	err := mq.qObject.Put(putmqmd, pmo, buffer)

	return err
}

// Disconnect from the queue manager
func close(mq *MQ) error {
	err := close(mq)
	if err == nil {
		fmt.Printf("Disconnected from queue manager %s\n", mq.qObject.Name)
	} else {
		fmt.Println(err)
	}
	return err
}

func init() {
	generalMQ := MQ{
		qMgrName:  getenv("QMGR_NAME", "qm1"),
		qName:     getenv("Q_NAME", "DEV.APP.QUEUE1"),
		mqHost:    getenv("Q_HOST", "localhost"),
		mqPort:    getEnvAsInt("Q_PORT", 1414),
		mqChannel: getenv("Q_CHANNEL", "DEV.APP.SVRCONN"),
	}
	log.Info("registering k6/x/mq")

	modules.Register("k6/x/mq", &generalMQ)
}

func getenv(key, fallback string) string {
	value := os.Getenv(key)
	if len(value) == 0 {
		return fallback
	}
	return value
}

func getEnvAsInt(key string, defaultValue int) int {
	if valueStr, exists := os.LookupEnv(key); exists {
		if value, err := strconv.Atoi(valueStr); err == nil {
			return value
		}
	}
	return defaultValue
}
