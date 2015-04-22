import usb.core
import time

class Robot():

    BASE_VALUES = {
        'shoulder': 64,
        'elbow':    16,
        'wrist':     4,
        'grip':      1,
    }

    STOP = [0, 0, 0]

    USB_VENDOR = 0x1267
    USB_PROD = 0x000

    def __init__(self):
        self.usbCon = None
        self.currentCommand = 0

    def connect(self):
        if self.usbCon != None:
            raise 'Already Connected'

        self.usbCon = usb.core.find(idVendor = self.USB_VENDOR, idProduct = self.USB_PROD)

        return self.usbCon != None

    def move(self,
            base = None,
            shoulder = None,
            elbow = None,
            wrist = None,
            grip = None,
            light = None,
            t = 0.5):

        command = self.buildState(base, shoulder, elbow, wrist, grip, light)
        print(command)
        # command = [153, 2, 1]
        self.send(command)
        time.sleep(t)
        self.send(self.STOP)

    def send(self, cmd):
        self.usbCon.ctrl_transfer(0x40, 6, 0x100, 0, cmd, 1000)

    def buildState(self,
            base = None,
            shoulder = None,
            elbow = None,
            wrist = None,
            grip = None,
            light = None):

        return [
            self.val(shoulder) * self.BASE_VALUES['shoulder'] +
            self.val(elbow) * self.BASE_VALUES['elbow'] +
            self.val(wrist) * self.BASE_VALUES['wrist'] +
            self.val(wrist) * self.BASE_VALUES['grip'],
            self.val(base),
            self.val(light) ]

    def val(self, v):
        if v == None or v == 'on':
            return 0
        if v == 'up' or v == 'left' or v == 'close' or v == 'off':
            return 1
        if v == 'down' or v == 'right' or v == 'open':
            return 2
