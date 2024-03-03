classdef DXLActuationPack < DXLCommunication

    properties (Access = public)
        % Public properties
        DXLIDArray
    end

    properties (Access = private)
        % Private properties
        
        ctrlTableMap
        portName
        baudRate
        torqueEnabledState
        presentPositions
        presentVelocities
        presentCurrents
        presentPWMs
        presentControllerStates

    end

    properties (Constant)
        % Constants
        ctrlModes = ["Current Control" "Velocity Control" "Position Control"...
            "Extended Position Control" "Current-based Position Control" ...
            "PWM Control"];
        ctrlModeArray = [0 1 3 4 5 16];

    end

    % Public methods
    methods (Access = public)
        % Constructor method
        function obj = DXLActuationPack(ctrlTableMap,portName,baudRate,dxlIDs)
            obj@DXLCommunication(ctrlTableMap,portName,baudRate);
            obj.DXLIDArray = dxlIDs;
            obj.torqueEnabledState = false;
        end

        function state = isTorqueEnabled(obj)
            state = obj.torqueEnabledState;
        end
        
        function data = getPresentPositions(obj)
            data = groupSyncRead(obj,obj.DXLIDArray,"Present Position");
            obj.presentPositions = data;
        end

        function data = getPresentVelocities(obj)
            data = groupSyncRead(obj,obj.DXLIDArray,"Present Velocity");
            obj.presentVelocities = data;
        end

        function data = getPresentMotorCurrents(obj)
            data = groupSyncRead(obj,obj.DXLIDArray,"Present Current");
            obj.presentCurrents = data;
        end

        function data = getPresentMotorPWMs(obj)
            data = groupSyncRead(obj,obj.DXLIDArray,"Present PWM");
            obj.presentPWMs = data;
        end

        function getPresentControllerModes(obj)
            data = groupSyncRead(obj,obj.DXLIDArray,"Operating Mode");
            for i = 1:length(data)
                ctrlModeIdx = find(obj.ctrlModeArray == data(i));
                fprintf('Control Mode: %s \n',obj.ctrlModes(ctrlModeIdx));
            end
            obj.presentControllerStates = data;
        end

        function setTargetPositions(obj,targetPositionArray)
            groupSyncWrite(obj,obj.DXLIDArray,"Goal Position",targetPositionArray);
        end

        function setTargetVelocities(obj,targetVelocityArray)
            groupSyncWrite(obj,obj.DXLIDArray,"Goal Velocity",targetVelocityArray);
        end

        function setTargetMotorCurrents(obj,targetCurrentArray)
            groupSyncWrite(obj,obj.DXLIDArray,"Goal Current",targetCurrentArray);
        end

        function setTargetMotorPWMs(obj,targetPWMArray)
            groupSyncWrite(obj,obj.DXLIDArray,"Goal PWM",targetPWMArray);
        end

        function setTargetMotorControllerlModes(obj,targetControllerMode)
            targetControllerModeArray = obj.ctrlModeArray(targetControllerMode)*ones(1,length(obj.DXLIDArray));
            groupSyncWrite(obj,obj.DXLIDArray,"Operating Mode",targetControllerModeArray);
        end

        function enableTorque(obj,torqueStatus)
            if torqueStatus == 1
                torqueStatusArray = ones(1,length(obj.DXLIDArray));
                fprintf("Torque Enabled... \n")
                obj.torqueEnabledState = true;
            elseif torqueStatus == 0
                torqueStatusArray = zeros(1,length(obj.DXLIDArray));
                fprintf("Torque Disabled... \n")
                obj.torqueEnabledState = false;
            end
            groupSyncWrite(obj,obj.DXLIDArray,"Torque Enable",torqueStatusArray);
        end

    end

    % Private methods
    methods (Access = private)

    end

end
