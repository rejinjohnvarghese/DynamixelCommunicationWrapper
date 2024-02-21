load('MX106ControlTable.mat', 'MX106ControlTable_ContainerMap')
dxlMotorPack = DXLActuationPack(MX106ControlTable_ContainerMap,'/dev/tty.usbserial-FT2H2Z5A',57600,[1 2 3 4])
dxlMotorPack.openPort
dxlMotorPack.enableTorque(1)
dxlMotorPack.setTargetPositions([2000 2000 2000 2000])
dxlMotorPack.getPresentPositions
dxlMotor.closePort