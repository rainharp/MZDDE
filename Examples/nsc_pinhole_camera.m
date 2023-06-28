clear all;
close all;
clc;

cd ..

ZOS = ZDDE();
TheApplication = ZOS.TheApplication;
TheApplication.PrimarySystem.New(false);                  % �½��ļ�
TheNCE = TheApplication.PrimarySystem.NCE;
TheSystem = TheApplication.PrimarySystem;
TheSystem.MakeNonSequential();                            % ����Ϊ������ģʽ

%% ���ι�Դ
TheNCE.InsertNewObjectAt(1);                              % ����������
SourceRectangle = TheNCE.GetObjectAt(1);     
ObjectType_SR = SourceRectangle.GetObjectTypeSettings(ZOSAPI.Editors.NCE.ObjectType.SourceRectangle);
SourceRectangle.ChangeType(ObjectType_SR);                % ��ȡ����������ĵ�1��������Ϊ���ι�Դ
SourceRectangle.Comment = '���ι�Դ';                     % ���ñ�ע
SourceRectangle.ObjectData.XHalfWidth = 2.5;              % ���� x ���
SourceRectangle.ObjectData.YHalfWidth = 2.5;              % ���� y ���
SourceRectangle.ObjectData.NumberOfLayoutRays = 2e4;      % �������й�������
SourceRectangle.ObjectData.NumberOfAnalysisRays = 1e9;    % ���÷�����������
SourceRectangle.SourcesData.SourceColor = ZOSAPI.Editors.NCE.SourceColorMode.D65White;  % ���ù�Դ��ɫΪ D65 �׹�

%% �õ�Ƭλ����
TheNCE.InsertNewObjectAt(2);                              % ����������
SlideSurface = TheNCE.GetObjectAt(2);
ObjectType_R = SlideSurface.GetObjectTypeSettings(ZOSAPI.Editors.NCE.ObjectType.Rectangle);
SlideSurface.ChangeType(ObjectType_R);                    % ��ȡ����������ĵ�2��������Ϊ����
SlideSurface.Comment = '�õ�Ƭ��Ƭ';                      % ���ñ�ע
SlideSurface.ObjectData.XHalfWidth = 2.5;                 % ���� x ���
SlideSurface.ObjectData.YHalfWidth = 2.5;                 % ���� y ���
SlideSurface.ZPosition = 1.0;                             % Z λ��

%% ����õ�Ƭ
TheNCE.InsertNewObjectAt(3);                              % ����������
Slide = TheNCE.GetObjectAt(3);
ObjectType_SL = Slide.GetObjectTypeSettings(ZOSAPI.Editors.NCE.ObjectType.Slide);
Slide.ChangeType(ObjectType_SL);                          % ��ȡ����������ĵ�3��������Ϊ�õ�Ƭ
Slide.Comment = '�õ�Ƭ';                                 % ���ûõ�Ƭ
Slide.RefObject = 2;                                      % ���òο�����
Slide.ZPosition = 1e-2;                                   % ���� Z λ��
Slide.ObjectData.XFullWidth = 2.5;                        % ���� x ȫ��
Slide.Comment = 'Alex200.BMP';                            % ����ע�ͣ��õ�Ƭ���ݣ�

%% ����С��
TheNCE.InsertNewObjectAt(4);                              % ����������
Pinhole = TheNCE.GetObjectAt(4);
ObjectType_AN = Slide.GetObjectTypeSettings(ZOSAPI.Editors.NCE.ObjectType.Annulus);
Pinhole.ChangeType(ObjectType_AN);                        % ��ȡ����������ĵ� 4 ��������Ϊ������
Pinhole.Comment = 'С��';                                 % ���ûõ�Ƭ
Pinhole.RefObject = 3;                                    % ���òο�����
Pinhole.ZPosition = 10;                                   % ���� Z λ��
Pinhole.Material = 'ABSORB';                              % ���ò���
Pinhole.ObjectData.MaxXHalfWidth = 9.0;                   % ���û������⾶
Pinhole.ObjectData.MaxYHalfWidth = 9.0;
Pinhole.ObjectData.MinXHalfWidth = 0.05;                  % ���û������ھ�
Pinhole.ObjectData.MinYHalfWidth = 0.05;

%% �����ɫ̽����
TheNCE.InsertNewObjectAt(5);                              % ����������
Detector = TheNCE.GetObjectAt(5);
ObjectType_DT = Slide.GetObjectTypeSettings(ZOSAPI.Editors.NCE.ObjectType.DetectorColor);
Detector.ChangeType(ObjectType_DT);
Detector.Comment = '��ɫ̽����';                          % ���ò�ɫ̽����
Detector.Material = 'ABSORB';                             % ���ò���
Detector.ZPosition = 25;                                  % ���� Z λ��
Detector.RefObject = 4;                                   % ���òο�����
Detector.ObjectData.NumberXPixels = 500;
Detector.ObjectData.NumberYPixels = 500;
Detector.ObjectData.XHalfWidth = 6.25;
Detector.ObjectData.YHalfWidth = 6.25;
Detector.ObjectData.Color = 4;                            % ����̽������ɫ����Ϊ4�������ɫ

%% ���ûõ�Ƭλ����ɢ��
% ����ɢ������
o3_Scatter = SlideSurface.CoatScatterData.GetFaceData(0).CreateScatterModelSettings(ZOSAPI.Editors.NCE.ObjectScatteringTypes.Lambertian);
o3_Scatter.S_Lambertian_.ScatterFraction = 1.0;
SlideSurface.CoatScatterData.GetFaceData(0).ChangeScatterModelSettings(o3_Scatter);
SlideSurface.CoatScatterData.GetFaceData(0).NumberOfRays = 1;
% ����ɢ��·��
SlideSurface.ScatterToData.ScatterToMethod = ZOSAPI.Editors.NCE.ScatterToType.ImportanceSampling; % ɢ��·��ģ�� --> �ص����
% �����ص��������
ImportanceData = SlideSurface.ScatterToData.GetRayData(1);
ImportanceData.Towards = 4;
ImportanceData.Size = 0.4;
ImportanceData.Limit = 1;
SlideSurface.ScatterToData.SetRayData(1,ImportanceData);

%% ����׷��
NSCRayTrace = TheSystem.Tools.OpenNSCRayTrace();
NSCRayTrace.SplitNSCRays = false;
NSCRayTrace.ScatterNSCRays = true;
NSCRayTrace.UsePolarization = false;
NSCRayTrace.IgnoreErrors = true;
NSCRayTrace.SaveRays = false;
NSCRayTrace.ClearDetectors(0);
NSCRayTrace.RunAndWaitForCompletion();
NSCRayTrace.Close();

%% ��̽��鿴��
analysis = TheSystem.Analyses.New_Analysis(ZOSAPI.Analysis.AnalysisIDM.DetectorViewer);


%% �����ļ�
TheApplication.PrimarySystem.SaveAs(fullfile(pwd, '\zmx files\Short course\Fundamentals of Optics\nsc_pinhole_camera.zmx'));