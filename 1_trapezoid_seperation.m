% G-code 파일 경로 설정
filename = 'housing_modeling_1124_0400.txt'; % 파일 이름 설정

% 파일 읽기
fid = fopen(filename, 'r');
if fid == -1
    error('파일을 열 수 없습니다: %s', filename);
end
gcode_lines = textscan(fid, '%s', 'Delimiter', '\n');
gcode_lines = gcode_lines{1};
fclose(fid);

% Z값 저장 변수 초기화
first_Z = NaN;
second_Z = NaN;
last_Z = NaN;

% Z값 추출
Z_values = []; % Z값들을 저장할 배열

for i = 1:length(gcode_lines)
    line = strtrim(gcode_lines{i});
    if startsWith(line, 'G0') || startsWith(line, 'G1')
        % Z값 추출
        Z_match = regexp(line, 'Z([-+]?\d*\.?\d+)', 'tokens');
        if ~isempty(Z_match)
            Z_value = str2double(Z_match{1}{1});
            Z_values = [Z_values; Z_value]; % Z값 배열에 추가
            
            % 첫 번째와 두 번째 Z값을 저장
            if isnan(first_Z)
                first_Z = Z_value; % 첫 번째 Z값 저장
            elseif isnan(second_Z)
                second_Z = Z_value; % 두 번째 Z값 저장
            end
            last_Z = Z_value; % 마지막 Z값 갱신
        end
    end
end

% 결과 계산
if length(Z_values) < 2
    error('파일에 최소 두 개 이상의 Z값이 필요합니다.');
else
    Z_diff_first_to_second = second_Z - first_Z; % 첫 번째와 두 번째 Z값의 차이
    Z_diff_first_to_last = last_Z - first_Z; % 첫 번째와 마지막 Z값의 차이
    middle = Z_diff_first_to_last / (2 * Z_diff_first_to_second); % middle 계산
    target_Z = first_Z + middle * Z_diff_first_to_second; % 목표 Z값 계산
end

% Z = target_Z 데이터에서 X값 최대 차이 계산
target_X_values = []; % 목표 Z값에서의 X값들을 저장
found_target_Z = false;

for i = 1:length(gcode_lines)
    line = strtrim(gcode_lines{i});
    if startsWith(line, 'G0') || startsWith(line, 'G1')
        % Z값 추출
        Z_match = regexp(line, 'Z([-+]?\d*\.?\d+)', 'tokens');
        if ~isempty(Z_match)
            current_Z = str2double(Z_match{1}{1});
            % 목표 Z값에서 데이터를 찾기 시작
            if abs(current_Z - target_Z) < 1e-3
                found_target_Z = true;
            elseif found_target_Z && abs(current_Z - target_Z) > 1e-3
                % 목표 Z값이 끝난 경우 반복 종료
                break;
            end
        end
        
        % X값 추출
        if found_target_Z
            X_match = regexp(line, 'X([-+]?\d*\.?\d+)', 'tokens');
            if ~isempty(X_match)
                X_value = str2double(X_match{1}{1});
                target_X_values = [target_X_values; X_value];
            end
        end
    end
end

% X값의 최대 차이 계산
if isempty(target_X_values)
    error('목표 Z값에서 유효한 X값 데이터를 찾을 수 없습니다.');
else
    max_X_difference = max(target_X_values) - min(target_X_values);
end

% 결과 출력
disp('첫 번째 Z값:');
disp(first_Z);
disp('두 번째 Z값:');
disp(second_Z);
disp('마지막 Z값:');
disp(last_Z);

disp('첫 번째와 두 번째 Z값의 차이:');
disp(Z_diff_first_to_second);

disp('첫 번째와 마지막 Z값의 차이:');
disp(Z_diff_first_to_second);

disp('Middle 값:');
disp(middle);

disp('Target Z값:');
disp(target_Z);

disp('Target Z값에서 X의 최대 차이:');
disp(max_X_difference);

% 입력값 설정
angle_deg = 30; % 각도 (각도는 두 밑변과 수직선의 각도)

% 각도 변환
angle_rad = deg2rad(angle_deg); % 각도를 라디안으로 변환

% 첫 번째 사다리꼴 (최종 목표) 계산
base_top_1 = max_X_difference; % 첫 번째 사다리꼴 윗변
base_bottom_1 = base_top_1 + 2 * Z_diff_first_to_last * tan(angle_rad); % 첫 번째 사다리꼴 밑변

x1_bottom_left = -base_bottom_1 / 2;
x1_bottom_right = base_bottom_1 / 2;
x1_top_left = -base_top_1 / 2;
x1_top_right = base_top_1 / 2;
y1_bottom = 0; % 첫 번째 사다리꼴 밑변 y 좌표
y1_top = Z_diff_first_to_last; % 첫 번째 사다리꼴 윗변 y 좌표

% 두 번째 사다리꼴 (시작점) 계산
base_top_2 = base_top_1 -  Z_diff_first_to_last * tan(angle_rad); % 두 번째 사다리꼴 윗변
base_bottom_2 = base_top_2 + 2 * Z_diff_first_to_second * tan(angle_rad); % 두 번째 사다리꼴 밑변

x2_bottom_left = -base_bottom_2 / 2;
x2_bottom_right = base_bottom_2 / 2;
x2_top_left = -base_top_2 / 2;
x2_top_right = base_top_2 / 2;
y2_bottom = 0; % 두 번째 사다리꼴 밑변 y 좌표
y2_top = Z_diff_first_to_second; % 두 번째 사다리꼴 윗변 y 좌표

% 사다리꼴 개수 계산
num_trapezoids = Z_diff_first_to_last / Z_diff_first_to_second;

% Figure 초기화
figure;
hold on;

% CSV 파일 초기화 (반복문 전에 실행)
output_filename = 'coordinates_with_layer.csv';
fid = fopen(output_filename, 'w');
if fid == -1
    error('파일을 저장할 수 없습니다: %s', output_filename);
end

% 헤더 추가
fprintf(fid, 'Layer,x_Bottom_Left,z_Bottom_Left,x_Bottom_Right,z_Bottom_Right,x_Top_Right,z_Top_Right,x_Top_Left,z_Top_Left\n');
fclose(fid);

% 등간격으로 사다리꼴 그리기
for i = 0:num_trapezoids
    % 현재 사다리꼴 비율
    ratio = i / num_trapezoids;
    
    % 현재 사다리꼴 속성 계산
    current_height = y2_top + ratio * (y1_top - y2_top);
    current_top = base_top_2 + ratio * (base_top_1 - base_top_2);
    current_bottom = base_bottom_2 + ratio * (base_bottom_1 - base_bottom_2);
    
    % 현재 사다리꼴 좌표 계산
    current_x_bottom_left = -current_bottom / 2;
    current_x_bottom_right = current_bottom / 2;
    current_x_top_left = -current_top / 2;
    current_x_top_right = current_top / 2;
    current_y_bottom = 0; % 항상 밑변 y 좌표는 0
    current_y_top = current_height; % 현재 높이

   
layer_num = i; % 현재 반복의 레이어 번호 (반복문 변수에 따라 설정)

% current_x_coords, current_y_coords 정의 (반복문 내에서 값 할당)
current_x_coords = [current_x_bottom_left, current_x_bottom_right, ...
                    current_x_top_right, current_x_top_left, current_x_bottom_left];
current_y_coords = [current_y_bottom, current_y_bottom, ...
                    current_y_top, current_y_top, current_y_bottom];

% 데이터를 파일에 추가 저장
fid = fopen(output_filename, 'a');
if fid == -1
    error('파일을 저장할 수 없습니다: %s', output_filename);
end

% 각 좌표를 문자열로 포맷팅
bottom_left = sprintf('%.6f,%.6f', current_x_coords(1), current_y_coords(1));
bottom_right = sprintf('%.6f,%.6f', current_x_coords(2), current_y_coords(2));
top_right = sprintf('%.6f,%.6f', current_x_coords(3), current_y_coords(3));
top_left = sprintf('%.6f,%.6f', current_x_coords(4), current_y_coords(4));

% 한 행에 레이어와 모든 좌표를 저장
fprintf(fid, '%d,%s,%s,%s,%s\n', layer_num, bottom_left, bottom_right, top_right, top_left);

fclose(fid);


    % 사다리꼴 윤곽선 그리기
    plot(current_x_coords, current_y_coords, '-', 'LineWidth', 1.5);
end

% 첫 번째 사다리꼴 추가 (최종 사다리꼴)
x1_coords = [x1_bottom_left, x1_bottom_right, x1_top_right, x1_top_left, x1_bottom_left];
y1_coords = [y1_bottom, y1_bottom, y1_top, y1_top, y1_bottom];
plot(x1_coords, y1_coords, '-', 'LineWidth', 2, 'DisplayName', '최종 사다리꼴');

% 두 사다리꼴을 잇는 직선을 y=0까지 연장
% 1. x1_top_right와 x2_top_right 연결 (y=0까지)
slope_top_right = (y1_top - y2_top) / (x1_top_right - x2_top_right);
x_intercept_top_right = x1_top_right - y1_top / slope_top_right;
plot([x1_top_right, x_intercept_top_right], [y1_top, 0], 'k--', 'LineWidth', 2, 'DisplayName', 'Top Right Line');
disp(['Top Right Line: y = ' num2str(slope_top_right) '*x + ' num2str(-slope_top_right * x1_top_right + y1_top)]);

% 2. x1_top_left와 x2_top_left 연결 (y=0까지)
slope_top_left = (y1_top - y2_top) / (x1_top_left - x2_top_left);
x_intercept_top_left = x1_top_left - y1_top / slope_top_left;
plot([x1_top_left, x_intercept_top_left], [y1_top, 0], 'r--', 'LineWidth', 2, 'DisplayName', 'Top Left Line');
disp(['Top Left Line: y = ' num2str(slope_top_left) '*x + ' num2str(-slope_top_left * x1_top_left + y1_top)]);

% 3. x1_bottom_left와 x2_bottom_left 연결 (y=0까지)
slope_bottom_left = (y1_bottom - y2_bottom) / (x1_bottom_left - x2_bottom_left);
x_intercept_bottom_left = x1_bottom_left; % y=0에서의 x 좌표는 그대로
plot([x1_bottom_left, x_intercept_bottom_left], [y1_bottom, 0], 'g--', 'LineWidth', 2, 'DisplayName', 'Bottom Left Line');
disp(['Bottom Left Line: y = ' num2str(slope_bottom_left) '*x + ' num2str(-slope_bottom_left * x1_bottom_left + y1_bottom)]);

% 4. x1_bottom_right와 x2_bottom_right 연결 (y=0까지)
slope_bottom_right = (y1_bottom - y2_bottom) / (x1_bottom_right - x2_bottom_right);
x_intercept_bottom_right = x1_bottom_right; % y=0에서의 x 좌표는 그대로
plot([x1_bottom_right, x_intercept_bottom_right], [y1_bottom, 0], 'b--', 'LineWidth', 2, 'DisplayName', 'Bottom Right Line');
disp(['Bottom Right Line: y = ' num2str(slope_bottom_right) '*x + ' num2str(-slope_bottom_right * x1_bottom_right + y1_bottom)]);

% 그래프 설정
title('등간격으로 비례하는 사다리꼴과 연결선');
xlabel('X 축');
ylabel('Y 축');
legend('show');
axis equal;
grid on;

hold off;

% 직선 방정식 정의
% Red Line (빨간색)
slope_red = (y1_top - y2_top) / (x1_top_left - x2_top_left);
intercept_red = y1_top - slope_red * x1_top_left;

% Black Line (검은색) %y절편
slope_black = (y1_top - y2_top) / (x1_top_right - x2_top_right);
intercept_black = y1_top - slope_black * x1_top_right;

% 파일 경로 설정
filename = 'housing_modeling_1124_0400.txt';
region1_file = fopen('region1.txt', 'w');
region2_file = fopen('region2.txt', 'w');
region3_file = fopen('region3.txt', 'w');

% 파일 읽기
fid = fopen(filename, 'r');
if fid == -1
    error('파일을 열 수 없습니다: %s', filename);
end

% 초기화
current_Z = NaN;

% 데이터 처리
while ~feof(fid)
    line = strtrim(fgets(fid));

    % Z값 추출
    if startsWith(line, 'G0') && contains(line, 'Z')
        Z_match = regexp(line, 'Z([-\d.]+)', 'tokens');
        if ~isempty(Z_match)
            current_Z = str2double(Z_match{1}{1});

            % Z값은 잉여 정보로 간주, 모든 파일에 기록
            fprintf(region1_file, '%s\n', line);
            fprintf(region2_file, '%s\n', line);
            fprintf(region3_file, '%s\n', line);
            continue;
        end
    end

    % 잉여 정보 처리
    if startsWith(line, ';') || startsWith(line, 'M')
        fprintf(region1_file, '%s\n', line);
        fprintf(region2_file, '%s\n', line);
        fprintf(region3_file, '%s\n', line);
        continue;
    end

    % X값 추출
    X_match = regexp(line, 'X([-+]?\d*\.?\d+)', 'tokens');
    if ~isempty(X_match)
        X_value = str2double(X_match{1}{1})-114;
        fprintf('X_value: %.3f\n', X_value);

        % Red Line과 Black Line 기준 계산
        red_z = slope_red * X_value + intercept_red;
        black_z = slope_black * X_value + intercept_black;

        % 1번 영역: X_value가 intercept_red 왼쪽에 있고 Z가 red_z 아래
        if (X_value < -intercept_red/slope_red) && (current_Z < red_z)
            fprintf(region1_file, '%s\n', line);

        % 2번 영역: 
        % (1) X_value가 intercept_red 왼쪽이고 Z가 red_z 위
        % (2) X_value가 intercept_red와 intercept_black 사이
        % (3) X_value가 intercept_black 오른쪽이고 Z가 black_z 위
        elseif (X_value <= -intercept_red/slope_red && current_Z >= red_z) || ...
               (X_value >= -intercept_red/slope_red && X_value <= -intercept_black/slope_black) || ...
               (X_value >= -intercept_black/slope_black && current_Z >= black_z)
            fprintf(region2_file, '%s\n', line);

        % 3번 영역: X_value가 intercept_black 오른쪽에 있고 Z가 black_z 아래
        elseif (X_value > -intercept_black/slope_black) && (current_Z < black_z)
            fprintf(region3_file, '%s\n', line);
        end
    end
end

% 파일 닫기
fclose(fid);
fclose(region1_file);
fclose(region2_file);
fclose(region3_file);

disp('G-code 분리가 완료되었습니다.');
