// Package amqp contains AMQP API for a remote server.
package mq

import (
	"fmt"
	"time"

	"github.com/ibm-messaging/mq-golang/v5/ibmmq"
	"go.k6.io/k6/js/modules"
)

const version = "v0.3.0"

// MQ type holds connection to a remote MQ Broker.
type MQ struct {
	qMgrName   string
	qName      string
	qMgrObject *ibmmq.MQQueueManager
	qObject    *ibmmq.MQObject
}

// Options defines configuration options for a MQ Connection.
type PutOptions struct {
	option1 string
}

// Start establishes a session with a MQ Broker given the provided options.
func (mq *MQ) Start() error {
	qMgrObject, err := ibmmq.Conn(mq.qMgrName)
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
func (mq *MQ) Put(options PutOptions) error {

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
		qMgrName: "QM1",
		qName:    "DEV.QUEUE.1",
	}

	modules.Register("k6/x/mq", &generalMQ)
}
