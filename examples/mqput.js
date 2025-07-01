import Mq from 'k6/x/mq';


export default function () {
    const url = "amqp://guest:guest@localhost:5672/"
    Mq.start()
    //Mq.put()
    Mq.putter("./examples/test.zip")
  
  }
  