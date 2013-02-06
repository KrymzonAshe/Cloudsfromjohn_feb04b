#include <LiquidCrystal.h>
#include "Wire.h" 
#define DS1307_I2C_ADDRESS 0x68 //set rtc
#include <OneWire.h>
#include <DallasTemperature.h> 
#define ONE_WIRE_BUS 6 //Define the pin of the DS18B20 
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  T E M P   P I N  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
OneWire oneWire(ONE_WIRE_BUS); 
DallasTemperature sensors(&oneWire);
#include "Wire.h" 
#define DS1307_I2C_ADDRESS 0x68 //set rtc
#include <LiquidCrystal.h> // initialize the library with the numbers of the interface pins
#include <OneWire.h>
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  T E M P   P I N  ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
OneWire ds(6);
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  T E M P   P I N  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/

const int floatswitch = A3;
int floatstate = 0;
const int topoffpump = A1;

// TEMP CONTROL
int fan = 4;
int heat = 2;
int toocold = 81;
int toohot = 82;
int idealtemp = 81;
int tempswing = 2;

// FAN CONTROL
int ledState1 = LOW;             
int ledState2 = LOW; 
long previousMillis1 = 0;        
long previousMillis2 = 0;

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  L E D   D I M M I N G   P A R T  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  F A D E S   I N   A N D   O U T  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
int blueramptime = 10 ;    // time for blue LEDs to dim on and off in minutes ***THIS is multiplied to be longer (somehow?) by temperature(); and topoff();
int whiteramptime = 10 ;  // time for white LEDs to dim on and off in minutes
int bluemin = 0 ;          // minimmum dimming value of blue LEDs, range of 0-255
int bluemax = 255 ;        // maximum dimming value of blue LEDs, range of 0-255
int whitemin = 0 ;         // minimum dimming value of white LEDs, range of 0-255
int whitemax = 255 ;       // maximum dimming value of white LEDs, range of 0-255
int photoperiod = 570 ;    // amount of time array is on at full power in minutes
int ontime = 10 ;          // time of day (hour, 24h clock) to begin photoperiod fade in
int blue = 3;              // blue LEDs connected to digital pin 3 (pwm)
int white = 5;            // white LEDs connected to digital pin 5 (pwm)
int ledfan = 111;        //this fan is for cooling the LEDs ***RETIRED

int bluepercent[11] = { 
  0, 50, 75, 100, 125 ,150, 175, 200, 225, 250, 255 };   // this line is needed if you are using meanwell ELN60-48P
int whitepercent[11] = { 
  0, 50, 75, 100, 125 ,150, 175, 200, 225, 250, 255 };   // these are the values in ~10% increments does not responde to <28

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  C L O U D S  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
//defines led random intensity range
int randNumber = random(20, 200);

//defines time delay ranges
int randTime1 = random(3000,12000); //time the cloud lasts
int randTime2 = random(10000,15000); //time between clouds

/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
LiquidCrystal lcd(7, 8, 9, 10, 11, 12); 
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  R T C   C L O C K   D S 1 3 0 7  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
byte decToBcd(byte val)   
{
  return ( (val/10*16) + (val%10) );
}
byte bcdToDec(byte val)  
{
  return ( (val/16*10) + (val%16) );
}
// 1) Sets the date and time on the ds1307
// 2) Starts the clock
// 3) Sets hour mode to 24 hour clock
// Assumes you're passing in valid numbers
void setDateDs1307(byte second, // 0-59
byte minute, // 0-59
byte hour, // 1-23
byte dayOfWeek, // 1-7
byte dayOfMonth, // 1-28/29/30/31
byte month, // 1-12
byte year) // 0-99
{
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  Wire.send(0);
  Wire.send(decToBcd(second)); // 0 to bit 7 starts the clock
  Wire.send(decToBcd(minute));
  Wire.send(decToBcd(hour));  
  Wire.send(decToBcd(dayOfWeek));
  Wire.send(decToBcd(dayOfMonth));
  Wire.send(decToBcd(month));
  Wire.send(decToBcd(year));
  Wire.endTransmission();
}
void getDateDs1307(byte *second,
byte *minute,
byte *hour,
byte *dayOfWeek,
byte *dayOfMonth,
byte *month,
byte *year)
{
  Wire.beginTransmission(DS1307_I2C_ADDRESS);
  Wire.send(0);
  Wire.endTransmission();
  Wire.requestFrom(DS1307_I2C_ADDRESS, 7);
  *second = bcdToDec(Wire.receive() & 0x7f);
  *minute = bcdToDec(Wire.receive());
  *hour = bcdToDec(Wire.receive() & 0x3f); // Need to change this if 12 hour am/pm
  *dayOfWeek = bcdToDec(Wire.receive());
  *dayOfMonth = bcdToDec(Wire.receive());
  *month = bcdToDec(Wire.receive());
  *year = bcdToDec(Wire.receive());
}



/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  D E F I N E  :  O N E S E C O N D |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
void onesecond() //function that runs once per second while program is running
{
  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
  getDateDs1307(&second, &minute, &hour, &dayOfWeek, &dayOfMonth, &month, &year);
  lcd.setCursor(0, 0);
  if(hour>0)
  {
    if(hour<=12)
    {
      lcd.print(hour, DEC);
    }
    else
    {
      lcd.print(hour-12, DEC);
    }
  }
  else
  {
    lcd.print("12");
  }
  lcd.print(":");
  if (minute < 10) {
    lcd.print("0");
  }
  lcd.print(minute, DEC);
  lcd.print(":");
  if (second < 10) {
    lcd.print("0");
  }
  lcd.print(second, DEC);
  if(hour<12)
  {
    lcd.print("am");
  }
  else
  {
    lcd.print("pm");
  }
  lcd.print(" ");
  delay(1000);
}

/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  D E F I N E  :  F A N S  O N |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
void fanon()
{
  digitalWrite(fan, HIGH);  
  lcd.setCursor(9, 3);
  lcd.print("Fan On ");
}
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  D E F I N E  :  F A N S   O F F |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
void fanoff()
{
  digitalWrite(fan, LOW);
  lcd.setCursor(9, 3);
  lcd.print("Fan Off");
}
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  D E F I N E  :  H E A T   O N |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
void heaton()
{
  digitalWrite(heat, HIGH);
  lcd.setCursor(0, 3);
  lcd.print("Heat On ");
}
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  D E F I N E  :  H E A T   OFF |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
void heatoff()
{
  digitalWrite(heat, LOW);
  lcd.setCursor(0, 3);
  lcd.print("Heat Off");
}
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  S E T U P  |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
void setup() {
  pinMode(heat, OUTPUT);
  pinMode(fan, OUTPUT);
  digitalWrite(heat, HIGH); //if mechanical relays start LOW when the arduino boots the devices will all turn on
  digitalWrite(fan, HIGH);     // Set analog pin 1 as a output
  pinMode(floatswitch, INPUT);
  pinMode(topoffpump, OUTPUT);
  digitalWrite(topoffpump, HIGH);
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  S E T U P - D I S P L A Y |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
  Wire.begin();

  // Change these values to what you want to set your clock to.
  // You probably only want to set your clock once and then remove
  // the setDateDs1307 call.

  second = 3;
  minute = 54;
  hour = 21;
  dayOfWeek = 1;  // Sunday is 0
  dayOfMonth = 21;
  month = 2;
  year = 11;
  setDateDs1307(second, minute, hour, dayOfWeek, dayOfMonth, month, year);
  //##################### UNCOMMENT THE ABOVE TO SET THE DATE & TIME #################################
  //##################################################################################################

  analogWrite(blue, bluemin);
  analogWrite(white, whitemin);
  lcd.begin(20, 4); // set up the LCD's number of rows and columns: 
  lcd.setCursor(0, 1);
  lcd.print("blue:");
  lcd.print(33*bluemin/85);
  lcd.setCursor(8, 1);
  lcd.print("white:");
  lcd.print(33*whitemin/85);  
}

/*|||||||||||||||||||||||||||||||||||||||||||  D E F I N E  :  T E M P   C O N T R O L ||||||||||||||||||||||||||||||||||||||||||||||*/
void temperature() 
{ 
  sensors.requestTemperatures(); // Send the command to get temperatures 
    delay(1500); 
  float temp2=0; 
  lcd.setCursor(13, 0); 
  temp2= sensors.getTempFByIndex(0); 
  lcd.print(sensors.getTempFByIndex(0));  
  lcd.print((char)223); 

  if(temp2>toohot) return fanon(),heatoff(); //these work, but cause a constant state of either relay being ON
  if(temp2<toocold) return heaton(),fanoff();

  /*
   //the below is for testing as of 8/5/2012...
      if (temp2<(idealtemp+tempswing) && temp2>(idealtemp-tempswing))          //turn off cooler/heater
   {
   digitalWrite(heat, LOW);
   digitalWrite(fan, LOW);   
   }
   if (tempswing>0)
   {
   if (temp2 >=(idealtemp+tempswing))                           //turn on fans
   {
   digitalWrite(fan, HIGH);
   }
   if (temp2<=(idealtemp-tempswing))                          //turn an heater
   {
   digitalWrite(heat, HIGH);
   }
   }
   */

}

/*|||||||||||||||||||||||||||||||||||||||||||  D E F I N E  :  T O P - O F F   C O N T R O L ||||||||||||||||||||||||||||||||||||||||||||||*/
void topoff()
{
  floatstate = digitalRead(floatswitch);
  if (floatstate == HIGH){
    digitalWrite(topoffpump, LOW);
  }
  else{
    digitalWrite(topoffpump,HIGH);
  }
  delay (1000);
}
/*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  L O O P |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
void loop()
{
  onesecond();
  temperature();
  topoff();

  /*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  L O O P - D I M   F U N C T I O N |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
  byte second, minute, hour, dayOfWeek, dayOfMonth, month, year;
  getDateDs1307(&second, &minute, &hour, &dayOfWeek, &dayOfMonth, &month, &year);
  int daybyminute = ((hour * 60) + minute); //converts time of day to a single value in minutes
  int bluerampup;
  if (daybyminute >= (ontime*60)) 
    bluerampup = (((ontime*60) + blueramptime) - daybyminute);
  else
      bluerampup = blueramptime;
  int whiterampup;
  if (daybyminute >= (ontime*60 + blueramptime)) 
    whiterampup = (((ontime*60) + blueramptime + whiteramptime) - daybyminute);
  else
      whiterampup = whiteramptime;
  int whiterampdown;
  if (((ontime * 60) + photoperiod + blueramptime + whiteramptime) <= daybyminute)
    whiterampdown = (((ontime*60) + photoperiod + blueramptime + 2*whiteramptime) - daybyminute);
  else
      whiterampdown = whiteramptime;
  int bluerampdown;
  if (((ontime * 60) + photoperiod + blueramptime + 2*whiteramptime) <= daybyminute)
    bluerampdown = (((ontime*60) + photoperiod + 2*blueramptime + 2*whiteramptime) - daybyminute);
  else
      bluerampdown = blueramptime;
  /*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  L O O P - F A D E  I N |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
  if (daybyminute >= (ontime*60))
  { 
    if (daybyminute <= ((ontime*60) + blueramptime + (whiteramptime/10*9))) //if time is in range of fade in, start fading in + (whiteramptime/10*9)
    {
      // fade blue LEDs in from min to max.
      for (int i = 1; i <= 10; i++) // setting ib value for 10% increment. Start with 0% 
      { 

        analogWrite(blue, bluepercent[i]); 
        lcd.setCursor(5, 1);
        lcd.print(i);
        lcd.print(" "); 
       int countdown = ((bluerampup*60)/10); // calculates seconds to next step
        while (countdown>0)
        {
          onesecond(); // updates clock once per second
          countdown--;
          temperature();
          topoff();
        }
      }     
      // fade white LEDs in from min to max.
      for (int i = 1; i <= 10; i++) // setting i value for 10% increment. Start with 0%
      { 
        analogWrite(white, whitepercent[i]); 
        lcd.setCursor(14, 1);
        lcd.print(i);
        lcd.print(" "); 
        int countdown = ((whiterampup*60)/10); // calculates seconds to next step
        while (countdown>0)
        {
          onesecond(); // updates clock once per second
          countdown--;
          temperature();
          topoff();
        }
      } 
    }
  }
  /*|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  L O O P - M A X  V A L U E |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
  if (daybyminute >= ((ontime * 60) + blueramptime + whiteramptime)) 
  { 
    if ( daybyminute < ((ontime * 60) + blueramptime + whiteramptime + photoperiod)) // if time is in range of photoperiod, turn lights on to maximum fade value
    {
        //lcd.setCursor(5, 1);
        //lcd.print(10);
        //lcd.print(" ");
        //lcd.setCursor(14, 1);
        //lcd.print(10);
        //lcd.print(" "); 
      /* 
       Dims leds from max power (255)        
       to a power value of 20-200 (based        
       on a 0-255 value range for led intensity)
       */
      for(int fade1Value = 255 ; fade1Value >= randNumber; fade1Value -=5)
      { 
        lcd.setCursor(0, 1);
        lcd.print("passing cloud...");
        analogWrite(blue, fade1Value); 
        analogWrite(white, fade1Value);
        delay(100);                            
      } 

      // holds dimmed state for 1-7 seconds
      delay(randTime1);
      // fades leds back to 255
      for(int fade2Value = randNumber; fade2Value <= 255; fade2Value +=5) 
      { 
    lcd.setCursor(0, 1);
    lcd.print("Sunshine        ");
        analogWrite(blue, fade2Value);
        analogWrite(white, fade2Value);
        delay(100);                            
      } 
      //waits 5-30 seconds before looping for next possible cloud                    
      delay(randTime2); 
    }
    lcd.setCursor(0, 2);
    lcd.print("passing cloud...");
    temperature();
    topoff();
  }
/*||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||  L O O P - F A D E  O U T |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||*/
  if (((ontime * 60) + photoperiod + blueramptime + whiteramptime) <= daybyminute)
  { 
    if (((ontime * 60) + photoperiod + whiteramptime + 2*blueramptime + (blueramptime/10*9)) >= daybyminute)
    {
      // fade white LEDs out from max to min in increments of 1 point:
      for (int i = 10; i >= 0; i--) // setting i value for 10% increment. Start with 10%
      { 
        analogWrite(blue, 255);
        lcd.setCursor(5, 1);
        lcd.print(10);
        lcd.print(" "); 
        analogWrite(white, whitepercent[i]); 
        lcd.setCursor(14, 1);
        lcd.print(i);
        lcd.print(" ");
        int countdown = ((whiterampdown*60)/10); // calculates seconds to next step
        while (countdown>0)
        {
          onesecond(); // updates clock once per second
          countdown--;
          temperature();
          topoff();
        }
      } 
      // fade blue LEDs out from max to min in increments of 1 point:
      for (int i = 10; i >= 0; i--) // setting i value for 10% increment. Start with 10%
      { 
        analogWrite(blue, bluepercent[i]);
        lcd.setCursor(5, 1);
        lcd.print(i);
        lcd.print(" "); 
        int countdown = ((bluerampdown*60)/10); // calculates seconds to next step
        while (countdown>0)
        {
          onesecond(); // updates clock once per second
            countdown--;
          temperature();
          topoff();
        }
      }
    }
  }
}  // END LOOP
