% 파일 처리 MATLAB 코드 (수정된 버전)

% 입력 파일 이름 설정
input_files = {'region_layered1.txt', 'region_layered3.txt', 'region2.txt'};
output_file = 'combined_layered_output.txt';

% 데이터 저장을 위한 Map 초기화
layer_data = containers.Map('KeyType', 'double', 'ValueType', 'any');

% 각 파일 처리
for i = 1:length(input_files)
    file_name = input_files{i};
    fid = fopen(file_name, 'r');
    if fid == -1
        error('파일 %s 을(를) 열 수 없습니다.', file_name);
    end
    
    current_layer = NaN;
    
    while ~feof(fid)
        line = strtrim(fgetl(fid)); % 줄 읽기 및 공백 제거
        if startsWith(line, ';LAYER:')
            % 현재 LAYER를 읽음
            current_layer = str2double(extractAfter(line, ':'));
            if ~isKey(layer_data, current_layer)
                layer_data(current_layer) = {}; % 초기화
            end
        elseif ~isempty(line) && ~startsWith(line, ';')
            % 데이터 추가
            if ~isnan(current_layer)
                temp_data = layer_data(current_layer); % 기존 데이터 가져오기
                temp_data{end+1} = line; % 데이터 추가
                layer_data(current_layer) = temp_data; % 업데이트
            end
        end
    end
    
    fclose(fid);
end

% 결과 파일 작성
fid_out = fopen(output_file, 'w');
if fid_out == -1
    error('출력 파일 %s 을(를) 생성할 수 없습니다.', output_file);
end

% LAYER 순서대로 정렬하여 출력
layer_keys = sort(cell2mat(keys(layer_data))); % LAYER 키 정렬
for i = 1:length(layer_keys)
    layer = layer_keys(i);
    fprintf(fid_out, ';---------------------------------------------\n');
    fprintf(fid_out, ';LAYER:%d\n', layer);
    data_lines = layer_data(layer);
    fprintf(fid_out, '%s\n', strjoin(data_lines, '\n')); % 데이터 출력
end

fclose(fid_out);

disp('LAYER별로 정리된 결과가 combined_layered_output.txt에 저장되었습니다.');
