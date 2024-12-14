**CAD/CAM(0568) 최종보고서에 첨부된 코드 모음**

[기하적 슬라이싱 방법 관련 코드] <br/>
1_trapezoid_seperation.m: 사다리꼴 별로 분리하고, 각 사다리꼴에 해당하는 꼭짓점 좌표 csv 파일로 저장 <br/>
2_layer_seperation.m: 영역 1, 영역 3에 대해 레이어를 슬라이싱 <br/>
3_combine_layers.m: 슬라이싱된 영역 1, 3 그리고 2의 레이어들을 통합 <br/>
4_combine_layers_txt_to_mat.m: 사다리꼴 레이어별로 통합된 txt 파일을 시뮬레이션을 위한 mat 파일로 변환 <br/>
5_gcode_visualization.m: 사다리꼴 레이어별로 분리된 Gcode를 레이어별로 시각화하는 코드 <br/>

[평면 슬라이싱 방법 관련 코드] <br/>
plane_separation_region1.m: 영역 1과 3분할 <br/>
plane_separation_region2.m: 영역 2 분할 <br/>
region_1_slicing.m: 영역 1과 3 레이어 슬라이싱 <br/>
region_2_slicing.m: 영역 2 레이어 슬라이싱 <br/>
final_combine_layers.m: 세 영역의 레이어를 합침 <br/>
visualize_combined_layers.m: 합쳐진 레이어 확인을 위해 시각화 <br/>
 
