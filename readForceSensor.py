import serial
import threading


class ArduinoSerialReader:
    def __init__(self, port, baudrate):
        self.port = port
        self.baudrate = baudrate
        self.ser = None
        self.isRunning = False
        self.sensorValue = None

    def connect(self):
        # Configure the serial port
        self.ser = serial.Serial(self.port, self.baudrate)

    def disconnect(self):
        # Close the serial port
        if self.ser:
            self.ser.close()

    def readData(self):
        while self.isRunning:
            # Read a line of data from the serial port
            data = self.ser.readline().decode().strip()
            # Process the data
            if data.startswith('!') and data.endswith('@'):
                sensor_value = float(data[1:-1])
            # Print the data
            print(data)

    def run(self):
        self.isRunning = True
        self.connect()
        # Start a separate thread to read data
        thread = threading.Thread(target=self.readData)
        thread.start()

    def stop(self):
        self.isRunning = False
        self.disconnect()


# Usage example
port = '/dev/cu.usbmodem21301'  # Replace with the appropriate port name
baudrate = 9600  # Set the baud rate to match the Arduino

reader = ArduinoSerialReader(port, baudrate)
reader.run()

# Do other tasks while the reader is running

# Stop the reader when done
reader.stop()

