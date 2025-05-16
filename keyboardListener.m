
function keyboardListener()
    global dxlMotorPack
    global motorPos_extended
    global motorPos_flexed
    
    motorPos_extended = [4000 6000 -1500 0 1800];
    motorPos_flexed = [-3000 -1000 -8000 -7000 -3500];
    
    load('MX106ControlTable_Container.mat', 'MX106ControlTable_ContainerMap');
    
    dxlMotorPack = DXLActuationPack(MX106ControlTable_ContainerMap,'/dev/tty.usbserial-FT2H2Z5A',115200,[0 1 2 3 4])
    dxlMotorPack.openPort
    pause(2)
    % dxlMotorPack.setTargetPositions([2000 2000 2000 2000])
    % dxlMotorPack.getPresentLEDStates
    dxlMotorPack.setTargetLEDStates(zeros(1,5));
    pause(2)

    dxlMotorPack.setOtherCommandValues("Current Limit",1*ones(1,5));
    % dxlMotorPack.setOtherCommandValues("Velocity Limit",1*ones(1,5));
    % dxlMotorPack.setOtherCommandValues("Profile Acceleration",20*ones(1,5));
    % dxlMotorPack.setOtherCommandValues("Profile Velocity",20*ones(1,5));
    % 
    % dxlMotorPack.setTargetMotorControllerlModes(5)
    % dxlMotorPack.setOtherCommandValues("Min Position Limit",[-3000 -1000 -8399 -7451 -3771]);
    % dxlMotorPack.setOtherCommandValues("Max Position Limit",[4055 6000 -1399 -519 1880]);
    dxlMotorPack.enableTorque(1)
    pause(2)
    dxlMotorPack.setTargetPositions(motorPos_extended)
    pause(2)
    % Display instructions
    fprintf('Keyboard Listener Started\n');
    fprintf('Press i, m, r, l, or t to see a message\n');
    fprintf('Press q to quit\n\n');
    
    % Create a figure to capture key pressesi
    fig = figure('Name', 'Keyboard Listener', 'NumberTitle', 'off', ...
                 'MenuBar', 'none', 'ToolBar', 'none', 'KeyPressFcn', @keyPressed, ...
                 'Position', [300, 300, 500, 300]);

             
    % Add text objects to display information
    titleText = uicontrol('Style', 'text', 'Position', [50, 250, 400, 30], ...
                         'String', 'Motor Unit Detection & Exo Control', ...
                         'FontSize', 16, 'FontWeight', 'bold');
                     
    keyText = uicontrol('Style', 'text', 'Position', [50, 180, 400, 30], ...
                         'String', 'Waiting to register key press...', ...
                         'FontSize', 14);
                     
    messageText = uicontrol('Style', 'text', 'Position', [50, 120, 400, 30], ...
                         'String', '', ...
                         'FontSize', 14);
                     
    % Store text objects in figure's UserData for access in callback
    userData.keyText = keyText;
    userData.messageText = messageText;
    set(fig, 'UserData', userData);
    
    % Keep the program running until 'q' is pressed
    global isRunning;
    isRunning = true;
    
    % Wait until user quits
    while isRunning
        drawnow;
        pause(0.1);
    end
    
    % Close the figure when done
    close(fig);
    fprintf('Keyboard listener stopped.\n');
end

function keyPressed(src, event)
    global dxlMotorPack
    global isRunning;
    global motorPos_extended
    global motorPos_flexed

    
    % Get the key that was pressed
    key = event.Key;
    
    % Get the text objects from UserData
    userData = get(src, 'UserData');
    keyText = userData.keyText;
    messageText = userData.messageText;
    
    % Update the key text
    set(keyText, 'String', ['Key press detected: ' upper(key)]);
    
    % Messages for different keys
    messages = struct();
    messages.i = 'Index finger motor unit detected. Activating motor 1';
    messages.m = 'Middle finger motor unit detected. Activating motor 2';
    messages.r = 'Ring finger motor unit detected. Activating motor 3';
    messages.l = 'Little finger motor unit detected. Activating motor 4';
    messages.t = 'Thumb motor unit detected. Activating motor 0';
    messages.o = 'Opening all fingers. Unwinding all motors';
    
    % Check which key was pressed and display appropriate message
    switch key
        case 't'
            message = messages.(key);
            set(messageText, 'String', message);
            fprintf('Finger detected %s: %s\n', key, message);
            dxlMotorPack.setTargetLEDStates([1 0 0 0 0]);
            dxlMotorPack.itemWrite(0,"Goal Position",motorPos_flexed(1))


        case 'i'
            message = messages.(key);
            set(messageText, 'String', message);
            fprintf('Finger detected %s: %s\n', key, message);
            dxlMotorPack.setTargetLEDStates([0 1 0 0 0]);
            dxlMotorPack.itemWrite(1,"Goal Position",motorPos_flexed(2))


        case 'm'
            message = messages.(key);
            set(messageText, 'String', message);
            fprintf('Finger detected %s: %s\n', key, message);
            dxlMotorPack.setTargetLEDStates([0 0 1 0 0]);
            dxlMotorPack.itemWrite(2,"Goal Position",motorPos_flexed(3))


        case 'r'
            message = messages.(key);
            set(messageText, 'String', message);
            fprintf('Finger detected %s: %s\n', key, message);
            dxlMotorPack.setTargetLEDStates([0 0 0 1 0]);
            dxlMotorPack.itemWrite(3,"Goal Position",motorPos_flexed(4))



        case 'l'
            message = messages.(key);
            set(messageText, 'String', message);
            fprintf('Finger detected %s: %s\n', key, message);
            dxlMotorPack.setTargetLEDStates([0 0 0 0 1]);
            dxlMotorPack.itemWrite(4,"Goal Position",motorPos_flexed(5))


        case 'q'
            fprintf('Motor port closed. Quitting...\n');
            dxlMotorPack.setTargetPositions(motorPos_extended);
            dxlMotorPack.enableTorque(0);
            dxlMotorPack.closePort
            isRunning = false;

        case 'o'
            message = messages.(key);
            set(messageText, 'String', message);
            fprintf('Open all fingers. Unwinding motors ...\n')
            dxlMotorPack.setTargetLEDStates([0 0 0 0 0]);
            dxlMotorPack.setTargetPositions(motorPos_extended)

        otherwise
            set(messageText, 'String', 'Unrecognized key');
            fprintf('Unrecognized key: %s\n', key);
    end
end