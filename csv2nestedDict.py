import csv
import json
import numpy as np

def csv2nestedDictFunc(csv_file_path):
    nested_dict = {}
    
    with open(csv_file_path, newline='') as csvfile:
        csvreader = csv.reader(csvfile)
        headers = next(csvreader)[1:]  # Get the headers (exclude the first column)
        
        for row in csvreader:
            primary_key = row[0]
            # Pair each header with the corresponding row entry (exclude the first column entry)
            inner_dict = {headers[i]: row[i+1] for i in range(len(headers))}
            nested_dict[primary_key] = inner_dict
            
    return nested_dict

# Example usage
import csv
import json
from DynamixelCommunication import DXLCommunication

def csv2nestedDictFunc(csv_file_path):
    nested_dict = {}
    
    with open(csv_file_path, newline='') as csvfile:
        csvreader = csv.reader(csvfile)
        headers = next(csvreader)[1:]  # Get the headers (exclude the first column)
        
        for row in csvreader:
            primary_key = row[0]
            # Pair each header with the corresponding row entry (exclude the first column entry)
            inner_dict = {headers[i]: row[i+1] for i in range(len(headers))}
            nested_dict[primary_key] = inner_dict
            
    return nested_dict

# Example usage
csv_file_path = 'Dynamixel Control Table Containers/MX106ControlTable_v2.csv'
nested_dict = csv2nestedDictFunc(csv_file_path)
print(nested_dict['Operating Mode']['DataAddress'])

# Save the dictionary to a JSON file
with open('Dynamixel Control Table Containers/MX106ControlTable_Dict.json', 'w') as json_file:
    json.dump(nested_dict, json_file)

dxlMotor = DXLCommunication(nested_dict, '/dev/tty.usbserial-FT2H2Z5A'.encode('utf-8'), 57600)

dxlMotor.openPort()
dxlMotor.ping([1, 2, 3, 4])
data2, success2 = dxlMotor.itemRead(1, 'LED')
print(data2,success2)
dxlMotor.itemWrite(1, 'LED', 1)
data3, success3 = dxlMotor.itemRead(1, 'LED')
print(data3,success3)
dxlMotor.itemWrite(1, 'LED', 0)
data4, success4 = dxlMotor.itemRead(1, 'LED')
print(data4,success4)
dxlMotor.itemWriteMultiple(range(1,5), ['LED']*4, [1]*4)
data , success = dxlMotor.itemReadMultiple(range(1,5), ['LED']*4)
print(data,success)

dxlMotor.groupSyncWrite(range(1,5), 'Goal Position', [0]*4)

data5, success5 = dxlMotor.itemReadMultiple(range(1,5), ['Present Position']*4)
print(data5,success5)


