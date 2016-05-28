program GameMain;
uses SwinGame, sgTypes;

procedure Main();
begin
  OpenGraphicsWindow('Procedural Map Generation', 800, 600);
  
  repeat
    ProcessEvents();
    
    ClearScreen(ColorWhite);
    
    RefreshScreen(60);
  until WindowCloseRequested();
end;

begin
  Main();
end.
