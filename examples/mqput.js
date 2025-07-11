import Mq from 'k6/x/mq';

Mq.start()

export default function () {
    Mq.putter("./examples/test.zip")  
}
  