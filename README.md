# video_processing

ball_hit_detector.sv에서 
collusion_detector 모듈의 fsm에서 prev, curr 변수에서 x pixel의 변화량 만큼을 탁구채의 속도로 인지해서 해당 변위만큼 estimated 변수에 넣고 game controller.sv의 입력으로 들어가는 상황

문제는 collusion pixel count는 감지 픽셀의 최소값을 정하는 건데 이 값이 estimated speed에 들어가서 실제 game controller에서 ball speed를 정확히 못 감지 하는 상황

건드려야할 부분: collusion detector의 fsm 특히 pixel 계산부와 state 최적화, game controller에서는 estimated를 받아서 단순히 연산을 하기 때문에 collusion detector 위주로 수정