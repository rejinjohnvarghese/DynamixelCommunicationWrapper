classdef DXLCommunication

    properties (Access = public)
        % Public properties
    end

    properties (Access = private)
        % Private properties

        portNum % variable for port number
        portName
        protocolVersion
        baudRate
        libName % load library into this variable
        ctrlTableMap
        packetHandler

        groupBulkRead_num
        groupBulkWrite_num

        dxl_comm_result
        dxl_error

    end

    properties (Constant)
        % Constants
        COMM_SUCCESS = 0;            % Communication Success result value
        COMM_TX_FAIL = -1001;        % Communication Tx Failed
    end

    % Public methods
    methods (Access = public)

        % Constructor for the DynamixelMotorComm class
        function obj = DXLCommunication(ctrlTableMap,portName,baudRate)
            % make sure library names are accurate or changed (also make
            % sure file path to libraries are added to MATLAB path, if not
            % make sure filepath is specified accurately)
            platforms = struct('PCWIN', 'dxl_x86_c', 'PCWIN64', 'dxl_x64_c', ...
                'GLNX86','libdxl_x86_c', 'GLNXA64', 'libdxl_x64_c', 'MACI64', ...
                'libdxl_maci_c', 'MACA64', 'libdxl_maca_c');
            obj.libName = platforms.(computer);

            % Load Libraries
            if ~libisloaded(obj.libName)
                [notfound, warnings] = loadlibrary(obj.libName, 'dynamixel_sdk.h', ...
                    'addheader', 'port_handler.h', 'addheader', 'packet_handler.h',...
                    'addheader','group_bulk_write.h','addheader','group_bulk_read.h',...
                    'addheader','group_sync_write.h','addheader','group_sync_read.h');
            end


            obj.ctrlTableMap = ctrlTableMap;
            obj.protocolVersion = obj.ctrlTableMap('Protocol Type').InitialValue;
            
            % Initialize PortHandler Structs
            % Set the port path
            % Get methods and members of PortHandlerLinux or PortHandlerWindows
            obj.portName = portName;
            obj.portNum = portHandler(portName);


            obj.baudRate = baudRate;

            % Initialize PacketHandler Structs
            packetHandler();

            obj.groupBulkRead_num = groupBulkRead(obj.portNum,obj.protocolVersion);
            obj.groupBulkWrite_num = groupBulkWrite(obj.portNum,obj.protocolVersion);

        end

        % destructor method
        function delete(obj)

            if libisloaded(obj.libName)
                % Close port
                closePort(obj.portNum);

                % Unload Library
                unloadlibrary(obj.libName);
            end
        end

        % itemWrite - Writes data to the specified register for a given motor
        function success = itemWrite(obj,id, queryName, data)
            % Inputs:
            %   id - Dynamixel ID to write data to
            %   queryName - Query Name from Control Table
            %   data - Data to write
            %
            % Outputs:
            %   success - Boolean indicating whether the data was successfully written
            
            dataLength = obj.ctrlTableMap(queryName).NumBytes;
            dataAddress = obj.ctrlTableMap(queryName).DataAddress;

            if dataLength == 1
                typecastdata = typecast(int8(data),'uint8');
                write1ByteTxRx(obj.portNum, obj.protocolVersion, id, dataAddress, typecastdata);
            elseif dataLength == 2
                typecastdata = typecast(int16(data),'uint16');
                write2ByteTxRx(obj.portNum, obj.protocolVersion, id, dataAddress, typecastdata);
            elseif dataLength == 4
                typecastdata = typecast(int32(data),'uint32');
                write4ByteTxRx(obj.portNum, obj.protocolVersion, id, dataAddress, typecastdata);
            end

            obj.dxl_comm_result = getLastTxRxResult(obj.portNum,obj.protocolVersion);
            obj.dxl_error = getLastRxPacketError(obj.portNum,obj.protocolVersion);
            success = obj.checkError();
        end

        % itemRead - Reads data from the specified register for a given motor
        function [state, success] = itemRead(obj,id, queryName)
            % Inputs:
            %   id - Dynamixel ID to read data from
            %   queryName - Query Name from Control Table
            %
            % Outputs:
            %   state - Read data
            %   success - Boolean indicating whether the read was successful
            %   DynamixelSDK uses 2's complement so we need to check to see
            %   if 'state' should be negative (hex numbers)


            dataLength = obj.ctrlTableMap(queryName).NumBytes;
            dataAddress = obj.ctrlTableMap(queryName).DataAddress;
 
            if dataLength == 1
                state = typecast(uint8(read1ByteTxRx(obj.portNum, ...
                    obj.protocolVersion, id, dataAddress)),'int8');
            elseif dataLength == 2
                state = typecast(uint16(read2ByteTxRx(obj.portNum, ...
                    obj.protocolVersion, id, dataAddress)),'int16');
            elseif dataLength == 4
                state = typecast(uint32(read4ByteTxRx(obj.portNum, ...
                    obj.protocolVersion, id, dataAddress)),'int32');
            end
            obj.dxl_comm_result = getLastTxRxResult(obj.portNum,obj.protocolVersion);
            obj.dxl_error = getLastRxPacketError(obj.portNum,obj.protocolVersion);
            success = obj.checkError();
        end

        % ping - Pings the given IDs to see if they are connected
        function success = ping(obj,ids)
            %
            % Inputs:
            %   ids - Vector of IDs to ping
            %
            % Outputs:
            %   success - Boolean indicating whether all pings were successful

            for idx = 1:length(ids)
                dxl_model_number(idx) = pingGetModelNum(obj.portNum, obj.protocolVersion, ids(idx));
                obj.dxl_comm_result = getLastTxRxResult(obj.portNum, obj.protocolVersion);
                obj.dxl_error = getLastRxPacketError(obj.portNum, obj.protocolVersion);
                success = obj.checkError();
                if success
                    fprintf('[ID:%03d] ping Succeeded. Dynamixel model number : %d\n', ids(idx), dxl_model_number(idx));
                else
                    disp('No Dynamixel pinged...')
                    success = false;
                    return
                end
            end
            success = true;
        end

        % initPort - Initializes the port and sets the baudRate
        function success = openPort(obj)
            % Inputs:
            %
            % Outputs:
            %   success - Boolean indicating whether the port was successfully opened and baudRate set

            % Open port
            if (openPort(obj.portNum))
                fprintf('Succeeded to open the port!\n');
            else
                unloadlibrary(obj.libName);
                fprintf('Failed to open the port!\n');
                success = false;
                return;
            end

            % Set port baudRate
            if (setBaudRate(obj.portNum, obj.baudRate))
                fprintf('Succeeded to apply desired baud rate!\n');
            else
                unloadlibrary(obj.libName);
                fprintf('Failed to change the baud rate!\n');
                success = false;
                return;
            end
            success = true;
        end

        function closePort(obj)
            % Close port
            if libisloaded(obj.libName)
                % Close port
                closePort(obj.portNum);
            end


        end


        % itemWriteMultiple - Sequentially writes the same data to the specified register for a group of motors
        function success = itemWriteMultiple(obj,ids, queryName, data)
            %
            % Inputs:
            %   ids - Vector of IDs to write data to
            %   queryName - Query Name from Control Table
            %   data - Data to write (could be a list [index matches index in 'ids' list] or a single value [for all ids])
            %
            % Outputs:
            %   success - Boolean indicating whether the data was successfully written
            %

            for idx = 1:length(ids)
                if length(queryName) == 1
                    successA = obj.itemWrite(ids(idx), queryName, data(idx));
                    if successA ~= true
                        success = false;
                        return
                    end
                elseif length(queryName) == length(ids)
                    successA = obj.itemWrite(ids(idx), queryName(idx), data(idx));
                    if successA ~= true
                        success = false;
                        return
                    end
                else
                    success = false;
                    return
                end

            end
            success = true;
        end

        % itemReadMultiple - Sequentially reads data from the specified register for a group of motors
        function [states, success] = itemReadMultiple(obj,ids, queryName)
            %
            % Inputs:
            %   ids - Vector of IDs to read data from
            %   queryName - Query Name from Control Table
            %
            % Outputs:
            %   states - Read data
            %   success - Boolean indicating whether the read was successful

  
            states = [];
            if length(queryName) == 1
                for idx = 1:length(ids)
                    [state, successA] = obj.itemRead(ids(idx), queryName);
                    if successA ~= true
                            states = [];
                        success = false;
                        return
                    end
                    states = [states, state];
                end
    
            elseif length(queryName) == length(ids)
                for idx = 1:length(ids)
                    [state, successB] = obj.itemRead(ids(idx), queryName(idx));
                    if successB ~= true
                            states = [];
                        success = false;
                        return
                    end
                    states = [states, state];
                end
            else
                success = false;
                return
            end





            success = true;
        end

        % syncWrite - Synchronously writes the same data to the specified register for a group of motors
        function success = groupSyncWrite(obj,ids, queryName, dataArray)
            % Inputs:
            %   ids - Vector of IDs to write data to
            %   queryName - Query Name from Control Table
            %   dataArray - Data array to write (could be a list [index matches index in 'ids' list] or a single value [for all ids])
            %
            % Outputs:
            %   success - Boolean indicating whether the data was successfully written
            %

            dataLength = obj.ctrlTableMap(queryName).NumBytes;
            dataAddress = obj.ctrlTableMap(queryName).DataAddress;

            % Initialize Groupsyncwrite Structs
            groupSyncWrite_num = groupSyncWrite(obj.portNum, obj.protocolVersion, dataAddress, dataLength);

            for idx = 1:length(ids)
                if dataLength == 1
                    dxl_addparam_result = groupSyncWriteAddParam(groupSyncWrite_num, ids(idx), typecast(int8(dataArray(idx)), 'uint8'), dataLength);
                elseif dataLength == 2
                    dxl_addparam_result = groupSyncWriteAddParam(groupSyncWrite_num, ids(idx), typecast(int16(dataArray(idx)), 'uint16'), dataLength);
                elseif dataLength == 4
                    dxl_addparam_result = groupSyncWriteAddParam(groupSyncWrite_num, ids(idx), typecast(int32(dataArray(idx)), 'uint32'), dataLength);
                end
                if dxl_addparam_result ~= true
                    fprintf('[ID:%03d] groupSyncWrite addparam failed', ids(idx));
                    return;
                end
            end

            % Syncwrite goal position
            groupSyncWriteTxPacket(groupSyncWrite_num);
            obj.dxl_comm_result = getLastTxRxResult(obj.portNum,obj.protocolVersion);
            obj.dxl_error = getLastRxPacketError(obj.portNum,obj.protocolVersion);
            success = obj.checkError();

            % Clear syncwrite parameter storage
            groupSyncWriteClearParam(groupSyncWrite_num);

        end

        % syncRead - Synchronously reads the same data from the specified register for a group of motors
        function [receivedData, success] = groupSyncRead(obj,ids, queryName)
            % Inputs:
            %   ids - Vector of IDs to read data from
            %   queryName - Query Name from Control Table
            %
            % Outputs:
            %   receivedData - Read data array
            %   success - Boolean indicating whether the read was successful

            dataLength = obj.ctrlTableMap(queryName).NumBytes;
            dataAddress = obj.ctrlTableMap(queryName).DataAddress;

            % Initialize Groupsyncread Structs 
            groupSyncRead_num = groupSyncRead(obj.portNum, obj.protocolVersion, dataAddress, dataLength);

            for idx = 1:length(ids)
                dxl_addparam_result = groupSyncReadAddParam(groupSyncRead_num, ids(idx));
                if dxl_addparam_result ~= true
                    fprintf('[ID:%03d] groupSyncRead addparam failed', ids(idx));
                    return;
                end
            end
            
            % Syncread
            groupSyncReadTxRxPacket(groupSyncRead_num);
            obj.dxl_comm_result = getLastTxRxResult(obj.portNum,obj.protocolVersion);
            obj.dxl_error = getLastRxPacketError(obj.portNum,obj.protocolVersion);
            success = obj.checkError();

            for idx = 1:length(ids)
                if (groupSyncReadIsAvailable(groupSyncRead_num, ids(idx), dataAddress, dataLength))
                    dxl_dataReceived(idx) = groupSyncReadGetData(groupSyncRead_num, ids(idx), dataAddress, dataLength);
                    if dataLength == 1
                        receivedData(idx) = typecast(uint8(dxl_dataReceived(idx)), 'int8');
                    elseif dataLength == 2
                        receivedData(idx) = typecast(uint16(dxl_dataReceived(idx)), 'int16');
                    elseif dataLength == 4
                        receivedData(idx) = typecast(uint32(dxl_dataReceived(idx)), 'int32');
                    end
                end
            end

            groupSyncReadClearParam(groupSyncRead_num);
        end

        % bulkWrite - Synchronously writes different data from the specified register for a group of motors
        function success = groupBulkWrite(obj,ids, queryNameArray, dataArray)

            % Inputs:
            %   ids - Vector of IDs to read data from
            %   queryNameArray - Query Name array from Control Table
            %   dataArray - dataArray to write to each motor and query name
            
            % Outputs:
            %   states - Read data
            %   success - Boolean indicating whether the read was successful
            

            
            for idx = 1:length(ids)
                dataLength = obj.ctrlTableMap(queryNameArray(idx)).NumBytes;
                dataAddress = obj.ctrlTableMap(queryNameArray(idx)).DataAddress;

                if dataLength == 1
                    dxl_addparam_result = groupBulkWriteAddParam(obj.groupBulkWrite_num, ids(idx), dataAddress, dataLength, typecast(int8(dataArray(idx)),'uint8'), dataLength);
                elseif dataLength == 2
                    dxl_addparam_result = groupBulkWriteAddParam(obj.groupBulkWrite_num, ids(idx), dataAddress, dataLength, typecast(int16(dataArray(idx)),'uint16'), dataLength);
                elseif dataLength == 4
                    dxl_addparam_result = groupBulkWriteAddParam(obj.groupBulkWrite_num, ids(idx), dataAddress, dataLength, typecast(int32(dataArray(idx)),'uint32'), dataLength);
                end

                if dxl_addparam_result ~= true
                    fprintf('[ID:%03d] groupBulkWrite addparam failed', ids(idx));
                    return;
                end
            end

            % Bulkwrite
            groupBulkWriteTxPacket(obj.groupBulkWrite_num);

            obj.dxl_comm_result = getLastTxRxResult(obj.portNum,obj.protocolVersion);
            obj.dxl_error = getLastRxPacketError(obj.portNum,obj.protocolVersion);
            success = obj.checkError();

            % Clear bulkwrite parameter storage
            groupBulkWriteClearParam(obj.groupBulkWrite_num);

        end

        % bulkRead - Synchronously reads different data from the specified register for a group of motors
        function [receivedData, success] = groupBulkRead(obj,ids, queryNameArray)
            %
            % Inputs:
            %   ids - Vector of IDs to read data from
            %   queryNameArray - Query Name array from Control Table
            %
            % Outputs:
            %   states - Read data
            %   success - Boolean indicating whether the read was successful

            for idx = 1:length(ids)
                dataLength = obj.ctrlTableMap(queryNameArray(idx)).NumBytes;
                dataAddress = obj.ctrlTableMap(queryNameArray(idx)).DataAddress;

                dxl_addparam_result = groupBulkReadAddParam(obj.groupBulkRead_num, ids(idx), dataAddress, dataLength);
                if dxl_addparam_result ~= true
                    fprintf('[ID:%03d] groupBulkRead addparam failed', ids(idx));
                    return;
                end
            end

            % Bulkread 
            groupBulkReadTxRxPacket(obj.groupBulkRead_num);
            obj.dxl_comm_result = getLastTxRxResult(obj.portNum,obj.protocolVersion);
            obj.dxl_error = getLastRxPacketError(obj.portNum,obj.protocolVersion);
            success = obj.checkError();

            
            for idx = 1:length(ids)
                dataLength = obj.ctrlTableMap(queryNameArray(idx)).NumBytes;
                dataAddress = obj.ctrlTableMap(queryNameArray(idx)).DataAddress;

                if (groupBulkReadIsAvailable(obj.groupBulkRead_num, ids(idx), dataAddress, dataLength))
                    dxl_dataReceived(idx) = groupBulkReadGetData(obj.groupBulkRead_num, ids(idx), dataAddress, dataLength);
                    if dataLength == 1
                        receivedData(idx) = typecast(uint8(dxl_dataReceived(idx)), 'int8');
                    elseif dataLength == 2
                        receivedData(idx) = typecast(uint16(dxl_dataReceived(idx)), 'int16');
                    elseif dataLength == 4
                        receivedData(idx) = typecast(uint32(dxl_dataReceived(idx)), 'int32');
                    end
                end
            end

            groupBulkReadClearParam(obj.groupBulkRead_num);
        end

    end

    % Private methods
    methods (Access = private)

        % checkError - Helper function to check error messages and print them if need be
        function success = checkError(obj)
            %
            % Inputs:
            %   dxl_comm_result - If nonzero, there is an error in the communication
            %   dxl_error - If nonzero, there is an error in something related to the data
            %
            % Outputs:
            %   success - Boolean indicating whether there was an error

            if obj.dxl_comm_result ~= obj.COMM_SUCCESS
                fprintf('%s\n', getTxRxResult(obj.protocolVersion,obj.dxl_comm_result));
                success = false;
                return
            elseif obj.dxl_error ~= 0
                fprintf('%s\n', getRxPacketError(obj.protocolVersion,obj.dxl_error));
                success = false;
                return
            else
                success = true;
            end
        end

    end

end
