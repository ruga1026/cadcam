
% 파일 경로 설정
input_filename = 'region1.txt';
output_filename = 'region_align1.txt';

% G-code 파일 읽기
fid = fopen(input_filename, 'r');
if fid == -1
    error('파일을 열 수 없습니다: %s', input_filename);
end
region_lines = textscan(fid, '%s', 'Delimiter', '\n');
region_lines = region_lines{1};
fclose(fid);

% 데이터 처리 초기화
current_Z = NaN; % 현재 Z 값을 저장
processed_lines = {}; % 처리된 G1 라인을 저장
layer_index = 0; % LAYER 구분용

% 데이터 처리
for i = 1:length(region_lines)
    line = strtrim(region_lines{i});
    
    % LAYER 구분
    if contains(line, ';LAYER:')
        layer_index = layer_index + 1;
        processed_lines{end+1} = line; % LAYER 정보를 그대로 저장
        continue;
    end
    
    % Z 값 추출 (G0 명령에서 Z 값을 추출)
    if startsWith(line, 'G0') && contains(line, 'Z')
        Z_match = regexp(line, 'Z([-+]?\d*\.?\d+)', 'tokens');
        if ~isempty(Z_match)
            current_Z = str2double(Z_match{1}{1});
        end
        processed_lines{end+1} = line; % G0 명령은 그대로 저장
        continue;
    end
    
    % G1 명령 데이터 처리
    if startsWith(line, 'G1')
        X_match = regexp(line, 'X([-+]?\d*\.?\d+)', 'tokens');
        Y_match = regexp(line, 'Y([-+]?\d*\.?\d+)', 'tokens');
        E_match = regexp(line, 'E([-+]?\d*\.?\d+)', 'tokens');
        
        % 기본 값 초기화
        X_value = NaN;
        Y_value = NaN;
        E_value = NaN;
        
        % 값 추출
        if ~isempty(X_match)
            X_value = str2double(X_match{1}{1});
        end
        if ~isempty(Y_match)
            Y_value = str2double(Y_match{1}{1});
        end
        if ~isempty(E_match)
            E_value = str2double(E_match{1}{1});
        end
        
        % Z 값과 함께 G1 라인 생성 및 저장
        if ~isnan(current_Z) && ~isnan(X_value) && ~isnan(Y_value) && ~isnan(E_value)
            updated_line = sprintf('G1 X%.3f Y%.3f Z%.3f E%.5f', X_value, Y_value, current_Z, E_value);
            processed_lines{end+1} = updated_line; % 처리된 G1 라인 저장
        end
    else
        % 기타 줄 처리 (그대로 저장)
        processed_lines{end+1} = line;
    end
end

% 결과를 region_align2.txt 파일에 저장
fid_out = fopen(output_filename, 'w');
if fid_out == -1
    error('파일을 저장할 수 없습니다: %s', output_filename);
end

% 정렬된 데이터를 파일에 작성
for i = 1:length(processed_lines)
    fprintf(fid_out, '%s\n', processed_lines{i});
end
fclose(fid_out);

disp('데이터가 region_align.txt 파일로 저장되었습니다.');


% region1.txt 파일 읽기
input_filename = 'region1.txt';
output_filename = 'region_align1.txt';

fid = fopen(input_filename, 'r');
if fid == -1
    error('파일을 열 수 없습니다: %s', input_filename);
end
region1_lines = textscan(fid, '%s', 'Delimiter', '\n');
region1_lines = region1_lines{1};
fclose(fid);

% 데이터 처리 초기화
estimated_size = sum(contains(region1_lines, 'G1')); % G1 라인 개수 추정
processed_lines = cell(estimated_size, 2); % 사전할당
line_index = 0; % 현재 저장된 라인 인덱스

% 데이터 처리
for i = 1:length(region1_lines)
    line = strtrim(region1_lines{i});
    fprintf("%2d% 정렬 진행 중\n", i/length(region1_lines));

    % Z 값 추출 (G0 명령에서만 Z 값을 추출)
    if startsWith(line, 'G0') && contains(line, 'Z')
        Z_match = regexp(line, 'Z([-+]?\d*\.?\d+)', 'tokens');
        if ~isempty(Z_match)
            current_Z = str2double(Z_match{1}{1});
        end
        continue; % 다음 라인으로 이동
    end
    
    % G1 명령 데이터 추출
    if startsWith(line, 'G1')
        X_match = regexp(line, 'X([-+]?\d*\.?\d+)', 'tokens');
        Y_match = regexp(line, 'Y([-+]?\d*\.?\d+)', 'tokens');
        E_match = regexp(line, 'E([-+]?\d*\.?\d+)', 'tokens');
        
        % 기본 값 초기화
        X_value = NaN;
        Y_value = NaN;
        E_value = NaN;
        
        % 값 추출
        if ~isempty(X_match)
            X_value = str2double(X_match{1}{1});
        end
        if ~isempty(Y_match)
            Y_value = str2double(Y_match{1}{1});
        end
        if ~isempty(E_match)
            E_value = str2double(E_match{1}{1});
        end
        
        % G1 라인 생성 및 저장
        if ~isnan(current_Z) && ~isnan(X_value) && ~isnan(Y_value) && ~isnan(E_value)
            updated_line = sprintf('G1 X%.3f Y%.3f Z%.3f E%.5f', X_value, Y_value, current_Z, E_value);
            line_index = line_index + 1;
            processed_lines{line_index, 1} = X_value;
            processed_lines{line_index, 2} = updated_line;
        end
    end
end

% 유효 데이터만 추출
processed_lines = processed_lines(1:line_index, :);

% 데이터를 X 값 기준으로 내림차순 정렬
processed_lines = sortrows(processed_lines, 1, 'descend');

% 정렬된 결과를 region_align1.txt 파일에 저장
fid_out = fopen(output_filename, 'w');
if fid_out == -1
    error('파일을 저장할 수 없습니다: %s', output_filename);
end

for i = 1:size(processed_lines, 1)
    fprintf(fid_out, '%s\n', processed_lines{i, 2});
end

fclose(fid_out);

disp('데이터가 region_align1.txt 파일로 저장되었습니다.');



% 파일 경로 설정
input_filename = 'region_align1.txt';
output_filename = 'region_layered1.txt';
coordinates_file = 'coordinates_with_layer.csv';

% G-code 및 coordinates_with_layer.csv 읽기
fid = fopen(input_filename, 'r');
region_lines = textscan(fid, '%s', 'Delimiter', '\n');
region_lines = region_lines{1};
fclose(fid);

coordinates_data = readtable(coordinates_file);

% 사다리꼴 기준선 설정
slope = tan(pi/2 - angle_rad); % region1 (+), 3 (-)에 따라 바꿔야함!
upper_offset = Z_diff_first_to_second * 0.5;
lower_offset = -Z_diff_first_to_second * 0.5;

% G1 명령만 필터링
relevant_lines = region_lines(contains(region_lines, 'G1'));

% X 및 Z 값 추출
num_lines = length(relevant_lines);
X_values = nan(num_lines, 1);
Z_values = nan(num_lines, 1);

X_pattern = 'X([-+]?\d*\.?\d+)';
Z_pattern = 'Z([-+]?\d*\.?\d+)';

X_tokens = regexp(relevant_lines, X_pattern, 'tokens');
Z_tokens = regexp(relevant_lines, Z_pattern, 'tokens');

for i = 1:num_lines
    if ~isempty(X_tokens{i})
        X_values(i) = str2double(X_tokens{i}{1}{1}) - 114;
    end
    if ~isempty(Z_tokens{i})
        Z_values(i) = str2double(Z_tokens{i}{1}{1});
    end
end

% 결과 파일 열기
fid_out = fopen(output_filename, 'w');
if fid_out == -1
    error('파일을 저장할 수 없습니다: %s', output_filename);
end

% 모든 레이어 처리
max_layer = max(coordinates_data.Layer);
for current_layer = 0:max_layer
    % 현재 레이어의 x_Bottom_Left와 x_Top_Left 값 가져오기
    layer_row = coordinates_data(coordinates_data.Layer == current_layer, :);
    if isempty(layer_row), continue; end
fprintf("%d레이어 출력 중..",current_layer);
    x_Bottom_Right = layer_row.x_Bottom_Left;
    x_Top_Right = layer_row.x_Top_Left;
    fprintf("%2d 레이어 진행 중\n", current_layer);

    % 레이어 헤더 추가
    fprintf(fid_out, ';---------------------------------------------\n');
    fprintf(fid_out, ';LAYER:%d\n', current_layer);

    % delta_X 계산
    delta_X = X_values - x_Bottom_Right;

    % 기준선 계산
    upper_target_z_base = slope * delta_X + upper_offset;
    lower_target_z_base = slope * delta_X + lower_offset;

    % 유효한 X 및 Z 값 인덱스 생성
    valid_idx = ~isnan(X_values) & ~isnan(Z_values);

    % X 조건 확인
    idx_X = (X_values >= x_Bottom_Right) & (X_values <= x_Top_Right);

    % Z 조건 확인
    idx_Z = (Z_values >= lower_target_z_base) & (Z_values <= upper_target_z_base);

    % 전체 조건 인덱스
    idx = valid_idx & idx_X & idx_Z;

    % 해당하는 라인 추출
    lines_to_write = relevant_lines(idx);

    % 파일에 작성
    for i = 1:length(lines_to_write)
        fprintf(fid_out, '%s\n', lines_to_write{i});
    end
end

fclose(fid_out);

disp('레이어 데이터를 region_layered.txt 파일에 저장했습니다.');
