require "libusb"
require "pusher-client"

class Robot
  def initialize
    @usb = LIBUSB::Context.new
    @usbCon = nil
    @currentCommand = 0
    @BASE_VALUES = {
        'shoulder' => 64,
        'elbow' =>    16,
        'wrist' =>     4,
        'grip' =>      1,
    }

    @STOP = [0,0,0]

    @USB_VENDOR = 0x1267
    @USB_PROD = 0x000
  end

  def connect
    return @usbCon if @usbCon
    @usbCon = @usb.devices(idVendor: @USB_VENDOR, idProduct: @USB_PROD).first
    return @usbCon != nil
  end

  def move(base = 0, shoulder = 0, elbow = 0, wrist = 0, grip = 0, light =0, t = 0.5)
    command = self.buildState(base, shoulder, elbow, wrist, grip, light)
    self.send(command)
    sleep(t)
    self.send(@STOP)
  end

  def send(cmd)
    return if @usbCon.nil?
    @usbCon.open_interface(0) do |handle|
      handle.control_transfer(bmRequestType: 0x40, bRequest: 6, wValue: 0x100, wIndex: 0x0000, dataOut: cmd.pack("c*"))
    end
  end

  def buildState(base = 0, shoulder = 0, elbow = 0, wrist = 0, grip = 0, light = 0)
    [
      self.val(shoulder) * @BASE_VALUES['shoulder'] +
      self.val(elbow) * @BASE_VALUES['elbow'] +
      self.val(wrist) * @BASE_VALUES['wrist'] +
      self.val(grip) * @BASE_VALUES['grip'],
      self.val(base),
      self.val(light)
    ]
  end

  def val(v)
    return 0 if v == 0 || v == 'off' || v == '0'
    return 1 if v == 'up' || v == 'left' || v == 'close' || v == 'on'
    return 2 if v == 'down' || v == 'right' || v == 'open'
  end

end

# Start of robot handling code

robot = Robot.new
robot.connect

socket = PusherClient::Socket.new("8e13eb33b3d6df4ba979", { secret: "b847765e341447f35440" })
socket.connect(true)

socket.subscribe('private-updates')

socket['private-updates'].bind('client-move-robot') do |data|
  moves = JSON.parse(data)
  robot.move(base = moves["base"], elbow = moves["elbow"], shoulder = moves["shoulder"], wrist = moves["wrist"], grip = moves["grip"], light = moves["light"], t = 0.5)
end

loop do
  sleep(1)
end