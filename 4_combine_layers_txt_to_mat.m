% G-code 파일 경로 설정
filename = 'combined_layered_output.txt'; % 실제 G-code 파일 이름으로 변경하세요

% 파일 읽기
fid = fopen(filename, 'r');
if fid == -1
    error('파일을 열 수 없습니다: %s', filename);
end
gcode_lines = textscan(fid, '%s', 'Delimiter', '\n');
gcode_lines = gcode_lines{1};
fclose(fid);

% 데이터 저장용 변수 초기화
combined_layers = {}; % cell 배열 초기화
current_layer = 0;

% G-code 라인 처리
for i = 1:length(gcode_lines)
    line = strtrim(gcode_lines{i});
    
    % LAYER 정보 추출
    if contains(line, ';LAYER:')
        layer_match = regexp(line, ';LAYER:(\d+)', 'tokens');
        if ~isempty(layer_match)
            current_layer = str2double(layer_match{1}{1}) + 1; % MATLAB 인덱스는 1부터 시작
            if length(combined_layers) < current_layer
                combined_layers{current_layer} = []; % 레이어 초기화
            end
        end
    elseif startsWith(line, 'G1') % G1 명령 처리
        % X, Y, Z 값 추출
        X_match = regexp(line, 'X([-+]?\d*\.?\d+)', 'tokens');
        Y_match = regexp(line, 'Y([-+]?\d*\.?\d+)', 'tokens');
        Z_match = regexp(line, 'Z([-+]?\d*\.?\d+)', 'tokens');
        
        if ~isempty(X_match) && ~isempty(Y_match) && ~isempty(Z_match)
            X = str2double(X_match{1}{1});
            Y = str2double(Y_match{1}{1});
            Z = str2double(Z_match{1}{1});
            
            % 레이어 데이터에 좌표 추가
            combined_layers{current_layer} = [combined_layers{current_layer}; X-114, Y, Z];
        end
    end
end

% .mat 파일로 저장
save('combined_layers.mat', 'combined_layers');
disp('combined_layers.mat 파일이 저장되었습니다.');
