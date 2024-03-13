import csv
import json

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

