% load('MX106ControlTable.mat', 'MX106ControlTable_ContainerMap')
dxlMotorPack = DXLActuationPack(MX106ControlTable_ContainerMap,'/dev/tty.usbserial-FT2H2Z5A',115200,[0 1 2 3 4])
dxlMotorPack.openPort
dxlMotorPack.enableTorque(1)
% dxlMotorPack.setTargetPositions([2000 2000 2000 2000])
% dxlMotorPack.getPresentLEDStates
dxlMotorPack.setTargetLEDStates(ones(1,5));
% dxlMotorPack.getOtherCommandValues("LED")

dxlMotorPack.setOtherCommandValues("Current Limit",10*ones(1,5));
dxlMotorPack.setOtherCommandValues("Velocity Limit",1*ones(1,5));
dxlMotorPack.setOtherCommandValues("Profile Acceleration",1*ones(1,5));
dxlMotorPack.setOtherCommandValues("Profile Velocity",1*ones(1,5));

dxlMotorPack.setTargetMotorControllerlModes(5)
dxlMotorPack.setOtherCommandValues("Min Position Limit",[-3000 -1000 -8399 -7451 -3771])
dxlMotorPack.setOtherCommandValues("Max Position Limit",[4055 6000 -1399 -519 1880])

% dxlMotorPack.setTargetPositions([1000 3000 -4000 -3000 -1000])
% dxlMotorPack.getPresentPositions
% dxlMotorPack.closePort