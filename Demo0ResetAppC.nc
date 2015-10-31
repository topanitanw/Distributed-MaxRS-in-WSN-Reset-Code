#include "Demo0Reset.h"
#define   NEW_PRINTF_SEMANTICS // printf
#include  "printf.h"           // printf

configuration Demo0ResetAppC {}
implementation {
  components MainC, Demo0ResetC as App, LedsC;

  components ActiveMessageC;
  components CC2420ControlC;  
  components new AMSenderC(AM_RADIO_SENSE_MSG);
  components new AMReceiverC(AM_RADIO_SENSE_MSG);

  components new HamamatsuS1087ParC() as LSensor;
  components new SensirionSht11C() as TSensor;

  components PrintfC;
  components SerialStartC;

  components UserButtonC;

  components new TimerMilliC();

  App.Boot -> MainC.Boot;

  App.Leds -> LedsC;

  App.MilliTimer -> TimerMilliC;

  App.LRead -> LSensor; // wire LRead to LSensor
  App.TRead -> TSensor.Temperature; // wire HRead to HSensor

  App.Get -> UserButtonC;
  App.Notify -> UserButtonC;

  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMPacket -> ActiveMessageC;

  //CC2420 stuffs for TinySPOTComm
  App.CC2420Config -> CC2420ControlC.CC2420Config;
  App.CC2420Power -> CC2420ControlC.CC2420Power;
  App.ReadRssi -> CC2420ControlC.ReadRssi;
  App.Resource -> CC2420ControlC.Resource;
}
