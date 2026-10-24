#include <Arduino.h>
#include <ros.h>
#include <std_msgs/msg/string.hpp>
#include <std_msgs/msg/int32.hpp>
#include <std_srvs/srv/set_bool.hpp>

ros::NodeHandle nh;
std_msgs::msg::String str_msg;
ros::Publisher pub("chatter", &str_msg);
std_msgs::msg::Int32 int_msg;
ros::Publisher int_pub("numbers", &int_msg);

void enable_led_service(const std_srvs::srv::SetBool::Request& req,
                            std_srvs::srv::SetBool::Response& res)
{
    digitalWrite(LED_BUILTIN, req.data ? HIGH : LOW);
    res.success = true;
    res.message = req.data ? "LED enabled" : "LED disabled";
}

ros::ServiceServer<std_srvs::srv::SetBool> service_server("enable_led", enable_led_service);

void setup() {
  nh.initNode();
  nh.advertise(pub);
  nh.advertise(int_pub);
  nh.advertiseService(service_server);

  str_msg.data = "Hello, ROS!";
  int_msg.data = 0;

  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, 0);

}

void loop() {
  // put your main code here, to run repeatedly:
  pub.publish(&str_msg);
  if (nh.connected()) {
    int_msg.data++;
    int_pub.publish(&int_msg);
  }
  nh.spinOnce();
  delay(1000);
}
