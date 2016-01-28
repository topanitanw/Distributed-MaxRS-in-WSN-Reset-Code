/*
 * Demo Paper Distributed MasRS in the WSN
 * Version: Demo0
 * - T:0x1205 should connect to the Basestation B:0x7F38.
 * *** While debugging, T:0x1205 connects to T:0x789B. ***
 * Author: Panitan Wongse-ammat
 */
#include "Timer.h"
#include "Demo0Reset.h"
#include "string.h"
#include <UserButton.h>
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

module Demo0ResetC @safe() {
  uses {
    interface Boot;

    interface Leds;

    interface Read<uint16_t> as LRead; // light sensor
    interface Read<uint16_t> as TRead; // temp sensor

    interface AMSend;
    interface Receive;
    interface Timer<TMilli> as MilliTimer;
    interface AMPacket;
    interface Packet;
    interface SplitControl as AMControl;

    interface Get<button_state_t>;
    interface Notify<button_state_t>;

    interface CC2420Config;
    interface CC2420Power;
    interface Read<uint16_t> as ReadRssi;
    interface Resource;
  }
}

implementation // the implementation part
{				 
  message_t packet;		 
  // the connecting node having_buddy = TRUE
  // except the T:0x1205 -> FALSE 
  uint16_t tsensor_reading = 0;
  uint16_t lsensor_reading = 0;

  event void Boot.booted() // when booted these functions will be called
  { 
    printf("\n\n\n\n-- Date: %s Time: %s --\n", __DATE__, __TIME__);
    printf("-- T:0x%04X BROADCAST_CONSTANT: 0x%02X -- \n", 
	   TOS_NODE_ID, BROADCAST_CONSTANT);
    /* printf("*** TOSH_DATA_LENGTH: %d ***\n", TOSH_DATA_LENGTH); */
    call AMControl.start();
    call CC2420Config.setPanAddr(1);
    call CC2420Config.setChannel(26);
    call Notify.enable();  
    call Leds.led0On();
    printfflush();  
  }

  event void TRead.readDone(error_t result, uint16_t data) 
  { // when the Temperature sensor is done, process the data
    // call TRead.read();
    if (result == SUCCESS)
    {
      int16_t temp = -38.4 + 0.0098 * data; // temp = 30c or 85f when data = 7000
      printf("TSensor reading data: %u temp C: %d\n", data, temp);
      tsensor_reading = data;
    } else
      printf("TSensor fails\n");
  }  

  event void LRead.readDone(error_t result, uint16_t data) 
  { // when the Light sensor is done, process the data
    if (result == SUCCESS)
    {
      printf("\n\nLSensor reading data: %u\n", data);
      lsensor_reading = data;

      if (data > LSENSOR_TH) 
	call Leds.led2On();
      else
	call Leds.led2Off();
    } else
      printf("LSensor fails\n");
  }  

  event void AMControl.stopDone(error_t err) {}
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {}
  event void CC2420Config.syncDone(error_t err) {}
  async event void CC2420Power.startOscillatorDone() {}
  async event void CC2420Power.startVRegDone() {}
  event void ReadRssi.readDone(error_t result, uint16_t val) {}
  event void Resource.granted() {}

  event void AMControl.startDone(error_t err) 
  {
    printf("*** Radio initialized ***\n");
  }

  event void MilliTimer.fired() 
  { 
    call TRead.read();
    call LRead.read();
  } // event void MilliTimer.fired() 

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, 
				   uint8_t len) 
  { 
    am_addr_t src_addr = call AMPacket.source(bufPtr);
    am_addr_t dst_addr = call AMPacket.destination(bufPtr);
    uint8_t pck_type = ((radio_msg_0*) payload)->type;
    printf("\n\nReceive Data type: %u, len: %u\n", pck_type, len);
    printf("Dst Addr: %04X | Src Addr: %04X\n", dst_addr, src_addr);

    if(pck_type == 0)
    { // reset
      radio_msg_0 msg0 = *((radio_msg_0*) payload);
      printf("Receive Pck Reset\n");
    } 
    printfflush();
    return bufPtr;
  }

  event void Notify.notify(button_state_t val) 
  { 
    radio_msg_0* pck0 = (radio_msg_0*) call Packet.getPayload(&packet, sizeof(radio_msg_0));
    pck0->type = 0;
    pck0->flooding = BROADCAST_CONSTANT;
    call AMSend.send(AM_BROADCAST_ADDR, 
		     &packet, 
		     sizeof(radio_msg_0));
    printf("Send the Reset Pck\n");
    printfflush();
  }
}

