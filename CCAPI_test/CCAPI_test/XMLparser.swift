//
//  XMLparser.swift
//  CCAPI_test
//
//  Created by Subeen on 9/27/25.
//

import Foundation

class DeviceDescriptionParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentValue = ""
    
    private var friendlyName = ""
    private var modelName = ""
    private var serialNumber = ""
    private var udn = ""
    private var ccapiURL = ""
    
    private var isParsingAccessURL = false
    
    func parse(_ xmlString: String) -> DeviceDescriptionResponse? {
        guard let data = xmlString.data(using: .utf8) else { return nil }
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            print("❌ XML parsing failed")
            return nil
        }
        
        guard !ccapiURL.isEmpty else {
            print("❌ No CCAPI URL found in device description")
            return nil
        }
        
        return DeviceDescriptionResponse(
            friendlyName: friendlyName,
            modelName: modelName,
            serialNumber: serialNumber,
            udn: udn,
            ccapiURL: ccapiURL
        )
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""
        
        // Check for X_accessURL with namespace
        if elementName == "X_accessURL" || qName?.contains("X_accessURL") == true {
            isParsingAccessURL = true
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch currentElement {
        case "friendlyName":
            friendlyName = currentValue
        case "modelName":
            modelName = currentValue
        case "serialNumber":
            serialNumber = currentValue
        case "UDN":
            udn = currentValue
        default:
            break
        }
        
        // Handle X_accessURL (with or without namespace)
        if (elementName == "X_accessURL" || qName?.contains("X_accessURL") == true) && isParsingAccessURL {
            ccapiURL = currentValue
            isParsingAccessURL = false
        }
        
        currentElement = ""
        currentValue = ""
    }
}
