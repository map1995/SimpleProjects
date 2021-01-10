; ### NAME        PureBasic Astroids
; ### Version     v0.0
; ### PB-Version  v5.72
; ### AUTHOR      Michael Alexander Pohlscheidt (MAP)
; ### DATE        08.01.2021
; ### 
; ### Version-Notes -----------------------------------------------------------------------------------------------------------
;    | o--> 0.0/08.01.2021/MAP - program created
;    |_________________________________________________________________________________________________________________________
;
; ### Todo-Notes --------------------------------------------------------------------------------------------------------------
;    | o--> Add a secound player.
;    | o--> Implement [ESC] to go back menu
;    | o--> Implement highscore
;    |_________________________________________________________________________________________________________________________
;
; ### Constants ###############################################################################################################
#WINDOW_ID = 0
#WINDOW_POS_X = 100
#WINDOW_POS_Y = 100
#WINDOW_WIDTH = 1024
#WINDOW_HEIGHT = 768
#WINDOW_TITLE = "PureBasic Astroids V0.0 | Created by Michael Alexander Pohlscheidt on 08.01.2021"
#WINDOW_SCREEN_POSITION_X = 0
#WINDOW_SCREEN_POSITION_Y = 0
#WINDOW_SCREEN_WIDTH = 1024
#WINDOW_SCREEN_HEIGHT = 768
#WINDOW_EVENT_NULL = 0

#SRT_PLAYER_ID = 0
#SRT_PLAYER_WIDTH = 16
#SRT_PLAYER_HEIGHT = 16
#SRT_BULLET_ID = 1
#SRT_BULLET_WIDTH = 16
#SRT_BULLET_HEIGHT = 16
#SRT_LIFE_BLOCK_ID = 2
#SRT_LIFE_BLOCK_WIDTH = 16
#SRT_LIFE_BLOCK_HEIGHT = 32
#SRT_GAME_OVER_ID = 3
#SRT_GAME_OVER_WIDTH = 96
#SRT_GAME_OVER_HEIGHT = 16
#SRT_GAME_OVER_ESC_KEY_ID = 4
#SRT_GAME_OVER_ESC_KEY_WIDTH = 196+32
#SRT_GAME_OVER_ESC_KEY_HEIGHT = 16

#PLY_LIFE_POINTS = 10
#PLY_MIN_ACCELERATION = 0.0
#PLY_MAX_ACCELERATION = 3.0
#PLY_CORRECTION_ANGLE = 45.0
#PLY_ACCELERATION_DECREASING_STEP_VALUE = 0.025
#BLT_LOOSING_LIFE_PER_LOOP_STEP = 0.25

#FLW_MENU = 0
#FLW_INGAME = 1
#FLW_GAMEOVER = 2

#ERR_MSG_TLE = "!ERROR APPEAR!"
#ERR_MSG_000 = "#ERR_MSG_000 - Error on method InitGame(). Game can't start!"
#ERR_MSG_001 = "#ERR_MSG_001 - Error on method CreateWindow(). Game can't start because OpenWindow() failed."
#ERR_MSG_002 = "#ERR_MSG_002 - Error on method CreateWindow(). Game can't start because OpenWindowedScreen() failed"
; ### STRUCTS #################################################################################################################
Structure Vector2D
  X.f
  Y.f
EndStructure

Structure GameObject
  Position.Vector2D
  Movement.Vector2D
  RotationAngle.i
EndStructure

Structure Player Extends GameObject
  Life.f
  RotateSpeed.f
  Acceleration.f
EndStructure

Structure Bullet Extends GameObject
  OriginPlayer.Player
  Demage.i
  MovementSpeed.f
  Life.f
EndStructure

Structure Astroids Extends GameObject
  Demage.i
EndStructure

; ### GLOBAL VARIABLES ########################################################################################################
Global _WindowMainIdValue
Global _CurrentWindowEvent
Global _Player1.Player
Global _CurrentFlow
Global NewList BulletsOnScreen.Bullet()

; ### METHODS #################################################################################################################

; --- InitGame ----------------------------------------------------------------------------------------------------------------
; Procedure instantiate sound, sprite and keyboard.
; If an error appear, close program and show error message.
Procedure InitGame()
  If InitSound() = 0 Or InitSprite() = 0 Or InitKeyboard() = 0
    MessageRequester(#ERR_MSG_TLE, #ERR_MSG_000)
    End
  EndIf 
EndProcedure

; --- CreateSprites -----------------------------------------------------------------------------------------------------------
; Procedure create all Sprites for this game.
Procedure CreateSprites()
  ; - Player Sprite -
  CreateSprite(#SRT_PLAYER_ID, #SRT_PLAYER_WIDTH, #SRT_PLAYER_HEIGHT) 
  If StartDrawing(SpriteOutput(#SRT_PLAYER_ID))
    DrawText(0,0,"->")
    StopDrawing()
  EndIf
  ; - Bullet Sprite -
  CreateSprite(#SRT_BULLET_ID, #SRT_BULLET_WIDTH, #SRT_BULLET_HEIGHT)
  If StartDrawing(SpriteOutput(#SRT_BULLET_ID))
    DrawText(0,0,":",RGB(255,255,0))
    StopDrawing()
  EndIf
  ; - Block Life Sprite -
  CreateSprite(#SRT_LIFE_BLOCK_ID, #SRT_LIFE_BLOCK_WIDTH, #SRT_LIFE_BLOCK_HEIGHT)
  If StartDrawing(SpriteOutput(#SRT_LIFE_BLOCK_ID))
    Box(0,0,#SRT_LIFE_BLOCK_WIDTH,#SRT_LIFE_BLOCK_HEIGHT,RGB(255,0,0))
    StopDrawing()
  EndIf
  ; - Game Over Layer -
  CreateSprite(#SRT_GAME_OVER_ID, #SRT_GAME_OVER_WIDTH, #SRT_GAME_OVER_HEIGHT)
  If StartDrawing(SpriteOutput(#SRT_GAME_OVER_ID))
    DrawText(0,0,"GAME OVER")
    StopDrawing()
  EndIf
  ; - Game Over Press Any Key Layer -
  CreateSprite(#SRT_GAME_OVER_ESC_KEY_ID, #SRT_GAME_OVER_ESC_KEY_WIDTH, #SRT_GAME_OVER_ESC_KEY_HEIGHT)
  If StartDrawing(SpriteOutput(#SRT_GAME_OVER_ESC_KEY_ID))
    DrawText(0,0,"Press [ESC] key to go main menu")
    StopDrawing()
  EndIf
EndProcedure

; --- CreateScreen ------------------------------------------------------------------------------------------------------------
; Create main window and the screen.
; If failed, error message will appear and programm will be closed.
Procedure CreateScreen()
  If OpenWindow(#WINDOW_ID, #WINDOW_POS_X, #WINDOW_POS_Y, #WINDOW_WIDTH, #WINDOW_HEIGHT, #WINDOW_TITLE) = 0
    MessageRequester(#ERR_MSG_TLE, #ERR_MSG_001)
    End
  EndIf
  
  _WindowMainIdValue = WindowID(#WINDOW_ID)
  
  If OpenWindowedScreen(_WindowMainIdValue, #WINDOW_SCREEN_POSITION_X, #WINDOW_SCREEN_POSITION_Y, #WINDOW_SCREEN_WIDTH, #WINDOW_SCREEN_HEIGHT) = 0
    MessageRequester(#ERR_MSG_TLE, #ERR_MSG_002)
    End
  EndIf
EndProcedure

; --- HandleWindowCloseEvent --------------------------------------------------------------------------------------------------
; Procedure handle the window close event. If window will be 
; closed, than also close the program.
; Only execute this procedure inside of "HandleWindowEvent()"
Procedure HandleWindowCloseEvent()
    If _CurrentWindowEvent = #PB_Event_CloseWindow
      End
    EndIf
EndProcedure

; --- HandleWindowEvent -------------------------------------------------------------------------------------------------------
; Procedure to handle all window events.
; It's the main handle procedure to execute subprocedures such as
; "HandleWindowCloseEvent()" 
Procedure HandleWindowEvent()
  Repeat
    _CurrentWindowEvent = WindowEvent()

    HandleWindowCloseEvent()
  Until _CurrentWindowEvent = #WINDOW_EVENT_NULL
EndProcedure

; --- InitGameObjects ---------------------------------------------------------------------------------------------------------
; Instantiate all game objects for this game.
Procedure InitGameObjects()
  ; --- Init Player 1 ---
  ; Player is on the center of screen
  positionPlayer1.Vector2D
  positionPlayer1\X = (#WINDOW_SCREEN_WIDTH / 2) - (#SRT_PLAYER_WIDTH / 2)
  positionPlayer1\Y = (#WINDOW_SCREEN_HEIGHT / 2) - (#SRT_PLAYER_HEIGHT / 2)    
  
  movementPlayer1.Vector2D
  movementPlayer1\X = 1
  movementPlayer1\Y = 1
  
  player1.Player
  player1\Life = #PLY_LIFE_POINTS
  player1\Position = positionPlayer1
  player1\Movement = movementPlayer1
  player1\RotationAngle = 0.0
  player1\RotateSpeed = 3.0
  player1\Acceleration = 0.0
  
  _Player1 = player1
EndProcedure

; --- RotateVector ------------------------------------------------------------------------------------------------------------
; Procedure will rotate the vector. Return the pointer value.
;
; *p_vector.Vector2d - pointer to a Vector2D struct
; p_angle.f - angle in degree to rotate the vector.
Procedure.i RotateVector(*p_vector.Vector2D, p_angle.f)  
 
  *p_vector\X = (Cos(Radian(p_angle))) - (Sin(Radian(p_angle)))
  *p_vector\Y = (Sin(Radian(p_angle))) + (Cos(Radian(p_angle)))

  ProcedureReturn *returnVector
EndProcedure

; --- CalculatePosition -------------------------------------------------------------------------------------------------------
; Calculate position. If GameObject is leaving the window, than
; it will come to other side.
Procedure CalculatePosition(*position.Vector2D, *movement.Vector2D, speed.f)
  ; set position to 0 if player is leaving to the right/bottom corner.
  newPosX = Mod(*position\X + *movement\X * speed, #WINDOW_SCREEN_WIDTH)
  newPosY = Mod(*position\Y + *movement\Y * speed, #WINDOW_SCREEN_HEIGHT)
  
  If newPosX < 0
    newPosX = #WINDOW_SCREEN_WIDTH
  EndIf
  
  If newPosY < 0
    newPosY = #WINDOW_SCREEN_HEIGHT
  EndIf
  
  *position\X = newPosX
  *position\Y = newPosY
EndProcedure

; --- HandlePlayer ------------------------------------------------------------------------------------------------------------
; Procedure handle all player action like movement, rotation and 
; shooting. This Procedure will only doing player action, if player
; has more than 0 life points.
Procedure HandlePlayer()
  If _Player1\Life > 0
    ; show player sprite and rotate them
    DisplaySprite(#SRT_PLAYER_ID, _Player1\Position\X, _Player1\Position\Y)
    RotateSprite(#SRT_PLAYER_ID, _Player1\RotationAngle, #PB_Absolute)
    ; show player life
    For indexBlock = 0 To _Player1\Life
      DisplaySprite(#SRT_LIFE_BLOCK_ID, (indexBlock * 18) + 2, 2)
    Next
    ; player control via keyboard
    If KeyboardPushed(#PB_Key_A)  ; rotate player counter clockwise
        _Player1\RotationAngle = _Player1\RotationAngle - _Player1\RotateSpeed
    EndIf
      
    If KeyboardPushed(#PB_Key_D)  ; rotate player clockwise
        _Player1\RotationAngle = _Player1\RotationAngle + _Player1\RotateSpeed
    EndIf
      
    If KeyboardPushed(#PB_Key_W)  ; increase player acceleration
      _Player1\Acceleration = #PLY_MAX_ACCELERATION
    EndIf
    
    If KeyboardPushed(#PB_Key_S)  ; increase player acceleration
      If _Player1\Acceleration > 0
        _Player1\Acceleration = _Player1\Acceleration - 0.075
      EndIf
    EndIf
    
    If KeyboardReleased(#PB_Key_X)  ; shooting some bullets
      bullet.Bullet
      bullet\Position = _Player1\Position
      bullet\RotationAngle = _Player1\RotationAngle
      bullet\OriginPlayer = _Player1
      bullet\Movement = _Player1\Movement
      bullet\MovementSpeed = 6.0
      bullet\Life = 100
      bullet\Demage = 1
      
      AddElement(BulletsOnScreen())
      BulletsOnScreen() = bullet
    EndIf
    
    ; calculation stuff for position etc.
    CalculatePosition(_Player1\Position, _Player1\Movement, _Player1\Acceleration)
    RotateVector(_Player1\Movement, _Player1\RotationAngle - #PLY_CORRECTION_ANGLE)
    ; decreasing acceleration of player
    If _Player1\Acceleration > #PLY_MIN_ACCELERATION
      _Player1\Acceleration = _Player1\Acceleration - #PLY_ACCELERATION_DECREASING_STEP_VALUE
    EndIf
  Else
    _CurrentFlow = #FLW_GAMEOVER
  EndIf
EndProcedure

; --- IsBulletTouchPlayer -----------------------------------------------------------------------------------------------------
; Return #True or #False value as byte if a bullet touch the player.
; *bullet.Bullet - The bullet to check collision with player
Procedure.b IsBulletTouchPlayer(*bullet.Bullet)
    isTouchedOnAxisX.b = #False
    isTouchedOnAxisY.b = #False
    
    If _Player1\Position\X >= *bullet\Position\X And _Player1\Position\X <= *bullet\Position\X + #SRT_BULLET_WIDTH
      isTouchedOnAxisX = #True
    EndIf
    
    If _Player1\Position\Y >= *bullet\Position\Y And _Player1\Position\Y <= *bullet\Position\Y + #SRT_BULLET_HEIGHT
      isTouchedOnAxisY = #True
    EndIf
    
    
    If isTouchedOnAxisX = #True And isTouchedOnAxisY = #True
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
EndProcedure

; --- HandleBullet ------------------------------------------------------------------------------------------------------------
; Process handle all bullets actions like movement, rotation and etc.
; Delete bullet form List, if life points is under 0.
Procedure HandleBullet()
  ForEach BulletsOnScreen()
    currentBullet.Bullet = BulletsOnScreen()
    currentBullet\Life = currentBullet\Life - #BLT_LOOSING_LIFE_PER_LOOP_STEP
    
    DisplaySprite(#SRT_BULLET_ID, currentBullet\Position\X, currentBullet\Position\Y)
    RotateSprite(#SRT_BULLET_ID, currentBullet\RotationAngle, #PB_Absolute)
    
    CalculatePosition(currentBullet\Position, currentBullet\Movement, currentBullet\MovementSpeed)
    
    If IsBulletTouchPlayer(currentBullet)
      currentBullet\Life = 0
      _Player1\Life = _Player1\Life - currentBullet\Demage
    EndIf
      
    If currentBullet\Life > 0
      BulletsOnScreen() = currentBullet
    Else
      DeleteElement(BulletsOnScreen())
    EndIf    
  Next
EndProcedure

Procedure HandleInGameFlow()
  ExamineKeyboard()
  
  FlipBuffers() 
  ClearScreen(RGB(0, 0, 0)) 
  
  HandleBullet()
  HandlePlayer()

EndProcedure

Procedure HandleGameOverFlow()
  ExamineKeyboard()
  
  FlipBuffers() 
  ClearScreen(RGB(0, 0, 0))
  
  DisplaySprite(#SRT_GAME_OVER_ID, (#WINDOW_SCREEN_WIDTH / 2) - (#SRT_GAME_OVER_WIDTH / 2), (#WINDOW_SCREEN_HEIGHT / 2) - (#SRT_GAME_OVER_HEIGHT / 2))
  DisplaySprite(#SRT_GAME_OVER_ESC_KEY_ID, (#WINDOW_SCREEN_WIDTH / 2) - (#SRT_GAME_OVER_ESC_KEY_WIDTH / 2), (#WINDOW_SCREEN_HEIGHT / 2) - (#SRT_GAME_OVER_ESC_KEY_HEIGHT / 2) + 16)
  
  If KeyboardReleased(#PB_Key_Escape)
    End
  EndIf 
EndProcedure

Procedure HandleFlow()
  If _CurrentFlow = #FLW_INGAME
    HandleInGameFlow()
  EndIf
  
  If _CurrentFlow = #FLW_GAMEOVER
    HandleGameOverFlow()
  EndIf
EndProcedure

; --- MAIN --------------------------------------------------------
InitGame()
CreateScreen()
CreateSprites()
InitGameObjects()

_CurrentFlow = #FLW_INGAME

Repeat
  HandleWindowEvent()
  HandleFlow()
ForEver
; IDE Options = PureBasic 5.72 (Windows - x64)
; CursorPosition = 392
; FirstLine = 276
; Folding = ---
; EnableXP