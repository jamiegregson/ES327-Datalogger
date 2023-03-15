// SET UP LIBRARIES AND DEFINITIONS
#include <Wire.h>
#include <SPI.h>
#include <Adafruit_Sensor.h>
#include "Adafruit_BME680.h"
#include "Adafruit_seesaw.h"
#include <SD.h>
#include "RTClib.h"
#include "DFRobot_OzoneSensor.h"
#include "bsec.h"
#include <FlashAsEEPROM.h>

#define BatteryPin A7
#define BME_SCK 13
#define BME_MISO 12
#define BME_MOSI 11
#define BME_CS 10
#define COLLECT_NUMBER   20
#define Ozone_IICAddress OZONE_ADDRESS_3

uint8_t bsecState[BSEC_MAX_STATE_BLOB_SIZE] = {0};
uint16_t stateUpdateCounter = 0;
const int chipSelect = 10;

Adafruit_seesaw ss;
Adafruit_BME680 bme;
File dataFile;
RTC_PCF8523 rtc;
DFRobot_OzoneSensor Ozone;
Bsec gassensor;
String output;



void setup() {
  Serial.begin(9600);
  Wire.begin();
  delay(3000);
  Serial.print("Start");

  // INITIALIZE SD CARD READER - IF NO SD CARD, ENTER CONFIG MODE
  if (!SD.begin(chipSelect)) {
  config();  
  }

  /////////////////////
  /// MEASUREMENT MODE
  /////////////////////

  // BME680 SETUP
  gassensor.begin(BME680_I2C_ADDR_SECONDARY, Wire);
  bsec_virtual_sensor_t sensorList[10] = {
    BSEC_OUTPUT_RAW_TEMPERATURE,
    BSEC_OUTPUT_RAW_PRESSURE,
    BSEC_OUTPUT_RAW_HUMIDITY,
    BSEC_OUTPUT_RAW_GAS,
    BSEC_OUTPUT_IAQ,
    BSEC_OUTPUT_STATIC_IAQ,
    BSEC_OUTPUT_CO2_EQUIVALENT,
    BSEC_OUTPUT_BREATH_VOC_EQUIVALENT,
    BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_TEMPERATURE,
    BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_HUMIDITY,
  };
  gassensor.updateSubscription(sensorList, 10, BSEC_SAMPLE_RATE_LP);
  
  // LOAD BME GAS MEASUREMENT STATE
  loadState();

  // INITIALISE RTC (REAL TIME CLOCK)
  if (! rtc.begin()) {
  }
  if (rtc.lostPower()) {
  rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }

  // INITIALIZE SD CARD READER
  while (!SD.begin(chipSelect));
  
  // INITIALIZE SOIL SENSOR
  while (!ss.begin(0x36));

  //INITIALISE SEN0321 OZONE SENSOR
  while(!Ozone.begin(Ozone_IICAddress));
  Ozone.setModes(MEASURE_MODE_PASSIVE); 

  //TIMER PIN SETUP
  int pin = 14;
  pinMode(pin, OUTPUT);

  // GET CURRENT DATE AND TIME FOR FILENAME
  DateTime now = rtc.now();
  String filename = String(now.day()) + String(now.hour()) + ".csv";
  File dataFile = SD.open(filename, FILE_WRITE);
  
  // WRITE HEADINGS IF LINE 1 EMPTY
  if (dataFile.position() == 0) { 
  dataFile.println("Date,Time,Temperature *C,Humidity %,Pressure hPa,Gas Resistance KOhms,Ozone ppb,Battery V,Soil Conductivity,Soil Temperature,Indoor Air Quality, CO2 Equivalent, VOC equivalent");
  }
 
  // PREHEAT
  unsigned long startTime = millis();
  int preheattime = 600000; // 10 mins

  while(millis() - startTime < preheattime) {
  float temperature = gassensor.temperature;
  float humidity = gassensor.humidity;
  float pressure = (gassensor.pressure/100);
  float gas = gassensor.gasResistance / 1000.0;
  float soilTemperature = ss.getTemp();
  float soilConductivity = ss.touchRead(0);
  int16_t ozoneConcentration = Ozone.readOzoneData(COLLECT_NUMBER);
  if (gassensor.run()) {
    float iaqTEMP = gassensor.iaq; 
    float co2eTEMP = gassensor.co2Equivalent;
    float VOCeTEMP = gassensor.breathVocEquivalent;
  }
  }
  
  // PREHEAT FINISHED. READ SENSOR DATA
  float temperature = gassensor.temperature;
  float humidity = gassensor.humidity;
  float pressure = (gassensor.pressure/100);
  float gas = gassensor.gasResistance / 1000.0;
  float soilTemperature = ss.getTemp();
  float soilConductivity = ss.touchRead(0);
  int16_t ozoneConcentration = Ozone.readOzoneData(COLLECT_NUMBER);
    if (gassensor.run()) {
  float iaqTEMP = gassensor.iaq; 
  float co2eTEMP = gassensor.co2Equivalent;
  float VOCeTEMP = gassensor.breathVocEquivalent;
  }

  // READ BATTERY VOLTAGE 
  float BatteryVoltage = analogRead(BatteryPin);
  BatteryVoltage *= 2;    // multiply by 2
  BatteryVoltage *= 3.3;  // multiply by ref voltage
  BatteryVoltage /= 1024; // convert analog reading to voltage

  // WRITE DATA TO .CSV FILE
  dataFile.print(now.day());
  dataFile.print(".");

  dataFile.print(now.month());
  dataFile.print(".");

  dataFile.print(now.year());
  dataFile.print(",");

  dataFile.print(now.hour());
  dataFile.print(":");

  dataFile.print(now.minute());
  dataFile.print(":");

  dataFile.print(now.second());
  dataFile.print(",");

  dataFile.print(temperature);
  dataFile.print(",");

  dataFile.print(humidity);
  dataFile.print(",");

  dataFile.print(pressure);
  dataFile.print(",");

  dataFile.print(gas);
  dataFile.print(",");

  dataFile.print(ozoneConcentration);
  dataFile.print(",");

  dataFile.print(BatteryVoltage);
  dataFile.print(",");

  dataFile.print(soilConductivity);
  dataFile.print(",");

  dataFile.print(soilTemperature);
  dataFile.print(",");

  dataFile.print(gassensor.iaq); 
  dataFile.print(",");

  dataFile.print(gassensor.co2Equivalent);
  dataFile.print(",");
  
  dataFile.println(gassensor.breathVocEquivalent);

  // CLOSE DATA FILE
  dataFile.close();
  delay(1000);

  //SEND HIGH SIGNAL TO TIMER BOARD TO POWER OFF
  digitalWrite(pin, HIGH);
}

void loop()
{
  // empty
}
