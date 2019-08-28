# pure-masterlist
Converts a Pure master list into XML. The tool outputs an XML file for organizations and one for persons, respectively.

Note: 
- This tool is entirely for educational purposes and should not relied on for production-ready data conversion. 
- It is not recommended to use this tool to make the final conversion - additional fields, filtering, restructuring, etc. may be desired and this should be done with care.
- Once you transition from the master list to XML synchronization, Pure will take over the existing content and you will not be able to revert back to the master list import. 

# Usage
`python3 ml2xml.py <excel_file>`

# Help:
`python3 ml2xml.py --help`

Note: The script assumes the XSL files are located in the same directory.

## Bugs?
Please open an issue here on Github or make a pull request.

# Requirements
- Python 3

See requirements.txt for pip packages used.


