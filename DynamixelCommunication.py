import numpy as np
import os, ctypes
os.sys.path.append('DynamixelSDK-master_modified/python/dynamixel_functions_py')             # Path setting
import dynamixel_functions as dynamixel  # Import the Dynamixel SDK



class DXLCommunication:
    # Class constants for communication results
    COMM_SUCCESS = 0
    COMM_TX_FAIL = -1001

    def __init__(self, ctrlTableMap, portName, baudRate):
        # Dynamixel SDK setup
        self.ctrlTableMap = ctrlTableMap
        self.protocolVersion = self.ctrlTableMap['Protocol Type']['InitialValue']  # Assuming ctrlTableMap is a dict
        self.portName = portName
        self.baudRate = baudRate
        
        # Initialize PortHandler
        self.portNum = dynamixel.portHandler(self.portName)
        
        # Initialize PacketHandler
        self.packetHandler = dynamixel.packetHandler()
        
        # Initialize groupBulkWrite instance
        self.groupBulWrite_num = dynamixel.groupBulkWrite(self.portNum,self.protocolVersion)
        # Initialize groupSyncWrite instance
        self.groupBulRead_num = dynamixel.groupBulkRead(self.portNum, self.protocolVersion)
        
        # Result and error properties
        self._dxlCommResult = None
        self._dxlError = None

    # def __del__(self):
    #     # Destructor to close the port
    #     self.closePort()

    def ping(self,ids):
        # Method to ping given IDs to check if they are connected
        for id in ids:
            # Try to ping the Dynamixel
            # Get Dynamixel model number
            dxlModelNumber = dynamixel.pingGetModelNum(self.portNum, self.protocolVersion, id)
            self._dxlCommResult = dynamixel.getLastTxRxResult(self.portNum, self.protocolVersion)
            self._dxlError = dynamixel.getLastRxPacketError(self.portNum, self.protocolVersion)
            if self._checkError():
                print("[ID:%03d] Ping Succeeded. Dynamixel model number : %d" % (id, dxlModelNumber))
            else:
                print("No Dynamixel pinged ...")
                return False
        return True

    def openPort(self):
        # Method to open the port and set baud rate
        if dynamixel.openPort(self.portNum):
            print("Succeeded to open the port!")
        else:
            print("Failed to open the port!")
            return False
        
        if dynamixel.setBaudRate(self.portNum, self.baudRate):
            print("Succeeded to change the baudrate!")
        else:
            print("Failed to change the baudrate!")
            return False
        return True

    def closePort(self):
        # Method to close the port
        if dynamixel.closePort(self.portNum):
            print("Succeeded to close the port!")
        else:
            print("Failed to close the port!")
            return False
        return True

    def itemWrite(self, id, queryName, data):
        # Method to write data to a specified register
        dataLength = int(self.ctrlTableMap[queryName]['NumBytes'])
        dataAddress = int(self.ctrlTableMap[queryName]['DataAddress'])
        if dataLength == 1:
            dynamixel.write1ByteTxRx(self.portNum, self.protocolVersion, id, dataAddress, data)
        elif dataLength == 2:
            dynamixel.write2ByteTxRx(self.portNum, self.protocolVersion, id, dataAddress, data)
        elif dataLength == 4:
            dynamixel.write4ByteTxRx(self.portNum, self.protocolVersion, id, dataAddress, data)

        self._dxlCommResult = dynamixel.getLastTxRxResult(self.portNum, self.protocolVersion)
        self._dxlError = dynamixel.getLastRxPacketError(self.portNum, self.protocolVersion)
        return self._checkError()

    def itemRead(self, id, queryName):
        # Method to read data from a specified register
        dataLength = int(self.ctrlTableMap[queryName]['NumBytes'])
        dataAddress = int(self.ctrlTableMap[queryName]['DataAddress'])
        if dataLength == 1:
            data = dynamixel.read1ByteTxRx(self.portNum, self.protocolVersion, id, dataAddress)
        elif dataLength == 2:
            data = dynamixel.read2ByteTxRx(self.portNum, self.protocolVersion, id, dataAddress)
        elif dataLength == 4:
            data = dynamixel.read4ByteTxRx(self.portNum, self.protocolVersion, id, dataAddress)

        self._dxlCommResult = dynamixel.getLastTxRxResult(self.portNum, self.protocolVersion)
        self._dxlError = dynamixel.getLastRxPacketError(self.portNum, self.protocolVersion)
        success = self._checkError()
        return data, success

    def itemWriteMultiple(self, ids, queryName, data):
        # Method to sequentially write data to a specified register for a group of motors        
        for idx in range(len(ids)):
            if len(queryName) == 1:
                successA = self.itemWrite(ids[idx], queryName[0], data[idx])
                if successA != True:
                    return False
            elif len(queryName) == len(ids):
                successA = self.itemWrite(ids[idx], queryName[idx], data[idx])
                if successA != True:
                    return False
            else:
                return False
        return True


    def itemReadMultiple(obj, ids, queryName):
        # Method to sequentially read data from a specified register for a group of motors
        dataArray = []
        success = True

        for idx in range(len(ids)):
            if len(queryName) == 1:
                data,successA = obj.itemRead(ids[idx], queryName)
                if not successA:
                    dataArray = []
                    success = False
                    return dataArray, success
                dataArray.append(data)
            elif len(queryName) == len(ids):
                data,successB = obj.itemRead(ids[idx], queryName[idx])
                if not successB:
                    dataArray = []
                    success = False
                    return dataArray, success
                dataArray.append(data)
        else:
            success = False
        
        return dataArray, success

    def groupSyncWrite(self, ids, queryName, dataArray):
        # Method to sequentially write data to a specified register for a group of motors
        dataLength = int(self.ctrlTableMap[queryName]['NumBytes'])
        dataAddress = int(self.ctrlTableMap[queryName]['DataAddress'])
    
        groupSyncWrite_num = dynamixel.groupSyncWrite(self.portNum, self.protocolVersion, dataAddress, dataLength)
        
        for idx in range(len(ids)):
            if dataLength == 1:
                print(1)
                dxl_addparam_result = ctypes.c_ubyte(dynamixel.groupSyncWriteAddParam(groupSyncWrite_num, ids[idx], dataArray[idx], dataLength)).value
            elif dataLength == 2:
                print(2)
                dxl_addparam_result = ctypes.c_ubyte(dynamixel.groupSyncWriteAddParam(groupSyncWrite_num, ids[idx], dataArray[idx], dataLength)).value
            elif dataLength == 4:
                print(4)
                dxl_addparam_result = ctypes.c_ubyte(dynamixel.groupSyncWriteAddParam(groupSyncWrite_num, ids[idx], dataArray[idx], dataLength)).value
            
            if dxl_addparam_result != True:
                print(f'[ID:{ids[idx]:03d}] groupSyncWrite addparam failed')
                return
        
        dynamixel.groupSyncWriteTxPacket(groupSyncWrite_num)
        self._dxlCommResult = dynamixel.getLastTxRxResult(self.portNum, self.protocolVersion)
        self._dxlError = dynamixel.getLastRxPacketError(self.portNum, self.protocolVersion)
        dynamixel.groupSyncWriteClearParam(groupSyncWrite_num)
        return self._checkError()


    def groupSyncRead(self, ids, queryName):
        # Method for synchronous reading from a group of motors
        pass

    def groupBulkWrite(self, ids, queryNameArray, dataArray):
        # Method for bulk writing to a group of motors
        pass

    def groupBulkRead(self, ids, queryNameArray):
        # Method for bulk reading from a group of motors
        pass

    def _checkError(self):
        if self._dxlCommResult != 0:
            print(dynamixel.getTxRxResult(self.protocolVersion, self._dxlCommResult))
            return False
        elif self._dxlError != 0:
            print(dynamixel.getRxPacketError(self.protocolVersion, self._dxlError))
            return False
        else:
            return True