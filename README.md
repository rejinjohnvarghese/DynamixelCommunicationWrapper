# Dynamixel Communication Wrapper
A wrapper in MATLAB that simplifies communication with Dynamixel motors. The wrapping class leverages a container created from the control table on https://emanual.robotis.com/docs/en/dxl/mx/mx-106-2/#control-table. DXLCommunication & DXLActuationPack class takes in as input the data name as a string to read from or write data to that register. Data address, size and data format are handled internally. DXLCommunication is the fundamental class, with the DXLActuationPack built on top of DXLCommunication. 

e.g. code for DXLCommunication

load('MX106ControlTable.mat', 'MX106ControlTable_ContainerMap')
% initiate instance of DXLCommunication class
dxlMotorPack = DynamixelMotorComm(MX106ControlTable_ContainerMap,'/dev/tty.usbserial-FT2H2Z5A',57600)
% get an idea of the keys of the registers provided by the control table
MX106ControlTable_ContainerMap.keys
% open port to DXL communication
dxlMotorPack.openPort
% synchronously read the LED status
dxlMotorPack.groupSyncRead([1 2 3 4],"LED")
% synchronously write to change LED status
dxlMotorPack.groupSyncWrite([1 2 3 4],"LED",[1 1 1 1])
% synchronously write to change Operating Mode status
dxlMotorPack.groupSyncWrite([1 2 3 4],"Operating Mode",[3 3 3 3])
% synchronously write to enable torque on all motors
dxlMotorPack.groupSyncWrite([1 2 3 4],"Torque Enable",[1 1 1 1])
% move motor 1 to position 1000
dxlMotorPack.itemWrite(1,"Goal Position",1000)
% read LED status of motor 2
dxlMotorPack.itemRead(2,"LED")
% synchronously move all motors to 0
dxlMotorPack.groupSyncWrite([1 2 3 4],"Goal Position",[0 0 0 0])
% synchronously read Present Position register from all motors
dxlMotorPack.groupSyncRead([1 2 3 4],"Present Position")
% synchronously write to different registers - LED & Goal Position in this case
dxlMotorPack.groupBulkWrite([1 2 3 4],["LED" "Goal Position" "Goal Position" "LED"],[0 1000 2000 0])
% synchronously read simultaneously from different registers
dxlMotorPack.groupBulkRead([1 2 3 4],["LED" "Goal Position" "Goal Position" "LED"])
% close port
dxlMotorPack.closePort


e.g. code for DXLActuationPack

