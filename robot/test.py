from robot import Robot

robot = Robot()
robot.connect()
# robot.move(base = 'right', elbow = 'down', shoulder = 'up', wrist = 'down', t = 3)
robot.move(base = 'left', elbow = 'down', shoulder = 'up', wrist = 'up', grip = 'close', light = 'off', t = 2)
robot.move(base = 'right', elbow = 'up', shoulder = 'down', wrist = 'down', grip = 'open', light = 'on', t = 2)