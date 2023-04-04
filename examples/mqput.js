import Mq from 'k6/x/mq';


export default function () {
    const url = "amqp://guest:guest@localhost:5672/"
    Mq.start({
      connection_url: url
    })
    
    const queueName = 'K6 queue'
    const exchangeName = 'K6 exchange'
  
    Queue.bind({
      queue_name: queueName,
      routing_key: '',
      exchange_name: exchangeName,
      no_wait: false,
      args: null
    })
  
    console.log(queueName + " queue binded to " + exchangeName)
  }
  