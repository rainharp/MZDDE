classdef ZDDE
% an encapsulated MATLAB class of ZOS-API for OpticStudio Zemax 19.4 SP2
% Author��Terrence
% Update Date: 2022.6.13

    properties
        Mode
        TheApplication
    end
    
    properties(Dependent)
        TheSystem
        LDE
        NCE
        MFE
        MCE
    end
    
    methods
        function obj = ZDDE(parameter)
        %   ���� MATLAB �� Zemax ������
        %
        %   ���ߣ�Tingyu Xue
        %	�������ڣ� 2021.9.16
        %	�����汾�� 1.0
        %   ���������� ��
        %
        %   �˺������Ӵ򿪵� Zemax ���̣�����ȫ�ֱ��� TheApplication
        %   ���� parameter�� zmx�ļ�����ʵ�����
        %   ����ֵ TheApplication��ZOSAPI TheApplication ����
        %   �ο���Zemax MATLAB Ӧ�÷���
        %
        %   global TheApplication;
        %   TheApplication = ZDDE();

            %% ������ʼ���Ӷ��� TheConnection
            global TheApplication;
            import System.Reflection.*;
            import ZOSAPI.*;

            % �ҵ���ǰ��װ�� OpticStudio �汾
            zemaxData = winqueryreg('HKEY_CURRENT_USER', 'Software\Zemax', 'ZemaxRoot');    % ��ȡ Zemax �ĵ�Ŀ¼
            NetHelper = strcat(zemaxData, '\ZOS-API\Libraries\ZOSAPI_NetHelper.dll');       % ��ȡ ZOSAPI_NetHelper.dll ·��
            % NetHelper = 'C:\Users\Documents\Zemax\ZOS-API\Libraries\ZOSAPI_NetHelper.dll';  % �Զ��� ZOSAPI_NetHelper.dll ·��
            NET.addAssembly(NetHelper);                                                     % �� ZOSAPI_NetHelper.dll ����� MATLAB   

            success = ZOSAPI_NetHelper.ZOSAPI_Initializer.Initialize();
            % success = ZOSAPI_NetHelper.ZOSAPI_Initializer.Initialize('C:\Program Files\OpticStudio\');  % ���Զ��� Zemax ����Ŀ¼��ʼ��
            if success == 1
                disp(strcat('Found OpticStudio at: ', char(ZOSAPI_NetHelper.ZOSAPI_Initializer.GetZemaxDirectory())));
            else
                % ����ʼ��ʧ�ܣ����ؿ�
                TheApplication = [];
                return;
            end

            % �� ZOS-API assemblies ����� MATLAB
            NET.addAssembly(AssemblyName('ZOSAPI_Interfaces'));
            NET.addAssembly(AssemblyName('ZOSAPI'));

            % ������ʼ���Ӷ���
            TheConnection = ZOSAPI.ZOSAPI_Connection();

            if ~exist('parameter', 'var')
                parameter = 0;
                instance = parameter;
            elseif strcmp(class(parameter), 'char')
                zfile_path = parameter;
            else
                try
                    parameter = int32(parameter);
                catch
                    parameter = 0;
                    warning('Invalid parameter {parameter}');
                end
                instance = parameter;
            end

            % ���Դ�����������

            % ע�� - ����ʾ 'Unable to load one or more of the requested types', 
            % ͨ������Ϊ�������� 32 λ�� Zemax �� 64 λ�� Matlab, �� 64 λ�� 
            % Matlab �� 32 λ�� Zemax�������� MATLAB �� .NET �Ľ�����ɵġ���ǰ
            % ֻ��ͨ����װͬΪ 32 λ�� 64 λ�� Zemax �� MATLAB �����

            %% ����չ��ʽ����
            if exist('instance', 'var')
                Mode = 'Extension';
                TheApplication = TheConnection.ConnectAsExtension(instance);
                if isempty(TheApplication)
                   HandleError('Failed to connect to OpticStudio!');
                end
                if ~TheApplication.IsValidLicenseForAPI
                    %TheApplication.CloseApplication();
                    %HandleError('License check failed!');
                    HandleError('ZDDE.m, License check failed! ����ʵ����ţ���ȷ���Ƿ��Ѵ� Zemax ������չ�ȴ����ӡ�');
                    TheApplication = [];
                end
            end

            %% �Զ���Ӧ�÷�ʽ����
            if exist('zfile_path','var')
                Mode = 'Standalone';
                % �ж��ļ��Ƿ���ڣ���������ڣ����ش���
                if exist(zfile_path) 
                    % ���·������������ȫ·��
                    if ~strcmp(':', zfile_path(2))
                        zfile_path = fullfile(pwd, zfile_path);
                    end
                    TheApplication = TheConnection.CreateNewApplication();
                    if isempty(TheApplication)
                        ME = MXException('An unknown connection error occurred!');
                        throw(ME);
                    end
                    if ~TheApplication.IsValidLicenseForAPI
                        ME = MXException('License check failed!');
                        throw(ME);
                        TheApplication = [];
                    end

                    if isempty(TheApplication)
                        % �����ʼ������ʧ��
                        disp('Failed to initialize a connection!');
                    else
                        try
                            TheApplication.PrimarySystem.LoadFile(zfile_path, false);% ��ģ��Zemax�ļ�
                        catch err
                            TheApplication.CloseApplication();
                            rethrow(err);
                        end
                    end
                else
                    % �� zfile_path ������
                    msgbox('+zdde\connect.m,  Zemax �ļ������ڣ�����ģ��Ŀ¼��');
                end
            end
            obj.TheApplication = TheApplication;
            obj.Mode = Mode;
        end
        
        function TheSystem = get.TheSystem(obj)
            TheSystem = obj.TheApplication.PrimarySystem;
        end
        
        function LDE = get.LDE(obj)
            LDE = obj.TheApplication.PrimarySystem.LDE;
        end
        
        function MFE = get.MFE(obj)
            MFE = obj.TheApplication.PrimarySystem.MFE;
        end
        
        function NCE = get.NCE(obj)
            NCE = obj.TheApplication.PrimarySystem.NCE;
        end
        
        function MCE = get.MCE(obj)
            MCE = obj.TheApplication.PrimarySystem.MCE;
        end
            
        function LDE_InsertECollimator(obj, varargin)
            % ������ģʽ�в����8�����׼ֱ������
            % InsertCollimator(3.850, 1.800, 'N-SF11', 0.198, 0.5);
            length = varargin{1};
            radius = varargin{2};
            material = varargin{3};
            d0 = varargin{4};
            semiDiameter = varargin{5};
            Tilt = varargin{6};
            obj.LDE.InsertNewSurfaceAt(1);
            obj.LDE.InsertNewSurfaceAt(1);
            obj.LDE.InsertNewSurfaceAt(1);

            Surface_1 = obj.LDE.GetSurfaceAt(0);
            Surface_2 = obj.LDE.GetSurfaceAt(1);
            Surface_3 = obj.LDE.GetSurfaceAt(2);
            Surface_4 = obj.LDE.GetSurfaceAt(3);

            % ���� d0, ͸������
            Surface_1.Thickness = 0;
            Surface_2.Thickness = d0;
            Surface_3.Thickness = length;
            Surface_4.Thickness = 0;

            % ���ò���
            Surface_1.Material = 'F_Silica';  
            Surface_2.Material = '';  
            Surface_3.Material = material;  
            Surface_4.Material = '';

            % ����͸���뾶�����ʰ뾶
            Surface_3.SemiDiameter = semiDiameter;
            Surface_4.SemiDiameter = semiDiameter;
            Surface_4.Radius = -radius;
            
            % ��������ɫ
            Surface_1.TypeData.RowColor = ZOSAPI.Common.ZemaxColor.Color13;
            Surface_2.TypeData.RowColor = ZOSAPI.Common.ZemaxColor.Color13;
            Surface_3.TypeData.RowColor = ZOSAPI.Common.ZemaxColor.Color13;
            Surface_4.TypeData.RowColor = ZOSAPI.Common.ZemaxColor.Color13;
            
            % ���� 8 ����
            SurfaceType_CB = Surface_2.GetSurfaceTypeSettings(ZOSAPI.Editors.LDE.SurfaceType.Tilted);
            Surface_2.ChangeType(SurfaceType_CB);
            Surface_2.SurfaceData.Y_Tangent = tan(Tilt*pi/180);
            Surface_3.ChangeType(SurfaceType_CB);
            Surface_3.SurfaceData.Y_Tangent = tan(Tilt*pi/180);

            % ����ע��
            Surface_1.Comment = '׼ֱ��';
            Surface_2.Comment = '׼ֱ��';
            Surface_3.Comment = '׼ֱ��';
            Surface_4.Comment = '׼ֱ��';
        end
        
        function LDE_InsertRCollimator(obj, varargin)
            length = varargin{1};
            radius = varargin{2};
            material = varargin{3};
            d0 = varargin{4};
            semiDiameter = varargin{5};
            Tilt = varargin{6};
            
            count = obj.LDE.NumberOfSurfaces;
            obj.LDE.InsertNewSurfaceAt(count-1);
            obj.LDE.InsertNewSurfaceAt(count-1);
            Surface_1 = obj.LDE.GetSurfaceAt(count-1);
            Surface_2 = obj.LDE.GetSurfaceAt(count);
            Surface_3 = obj.LDE.GetSurfaceAt(count+1);
            
            % ����͸�����ȣ����ʣ��뾶, d0
            Surface_1.Thickness = length;
            Surface_1.Radius = radius;
            Surface_1.SemiDiameter = semiDiameter;
            Surface_2.SemiDiameter = semiDiameter;
            Surface_3.SemiDiameter = semiDiameter;  
            Surface_2.Thickness = d0;
            
            % ���� 8 ����
            SurfaceType_CB = Surface_2.GetSurfaceTypeSettings(ZOSAPI.Editors.LDE.SurfaceType.Tilted);
            Surface_2.ChangeType(SurfaceType_CB);
            Surface_2.SurfaceData.Y_Tangent = tan(Tilt*pi/180);
            Surface_3.ChangeType(SurfaceType_CB);
            Surface_3.SurfaceData.Y_Tangent = tan(Tilt*pi/180);

            % ���ò���
            Surface_1.Material = material;  
            Surface_2.Material = '';  
            Surface_3.Material = 'F_Silica';  
            
            % ��������ɫ
            Surface_1.TypeData.RowColor = ZOSAPI.Common.ZemaxColor.Color13;
            Surface_2.TypeData.RowColor = ZOSAPI.Common.ZemaxColor.Color13;
            Surface_3.TypeData.RowColor = ZOSAPI.Common.ZemaxColor.Color13;
            
            % ����ע��
            Surface_1.Comment = '׼ֱ��';
            Surface_2.Comment = '׼ֱ��';
            Surface_3.Comment = '׼ֱ��';
        end
        
        function New(obj)
            obj.TheApplication.PrimarySystem.New(false);
        end
        
        function Open(obj, filename)
            obj.TheApplication.PrimarySystem.LoadFile(filename, false);
        end
        
        function Save(obj)
            obj.TheApplication.PrimarySystem.Save;
        end
        
        function SaveAs(obj, filename)
            obj.TheApplication.PrimarySystem.SaveAs(filename);
        end
        
        function Optimize(obj)
            LocalOpt = obj.TheApplication.PrimarySystem.Tools.OpenLocalOptimization();
            LocalOpt.Algorithm = ZOSAPI.Tools.Optimization.OptimizationAlgorithm.DampedLeastSquares;
            LocalOpt.Cycles = ZOSAPI.Tools.Optimization.OptimizationCycles.Automatic;
            LocalOpt.NumberOfCores = 8;
            LocalOpt.RunAndWaitForCompletion();
            LocalOpt.Close();
        end
        
        function IL = getIL(obj)
            TheSystem = obj.TheApplication.PrimarySystem;
            nsur = TheSystem.LDE.NumberOfSurfaces;
            Efficiency = TheSystem.MFE.GetOperandValue(ZOSAPI.Editors.MFE.MeritOperandType.POPD, nsur, 0, 0, 0, 0, 0, 0, 0);
            IL = -10 * log10(Efficiency);
        end
        
        function setNA(obj, NA)
            obj.TheApplication.PrimarySystem.SystemData.Aperture.ApertureType = ZOSAPI.SystemData.ZemaxApertureType.ObjectSpaceNA;
            obj.TheApplication.PrimarySystem.SystemData.Aperture.ApertureValue = NA;
            obj.TheApplication.PrimarySystem.SystemData.Aperture.ApodizationType = ZOSAPI.SystemData.ZemaxApodizationType.Gaussian;
            obj.TheApplication.PrimarySystem.SystemData.Aperture.ApodizationFactor = 1;
        end
        
        function setStop(obj, surfaceID)
            obj.TheApplication.PrimarySystem.LDE.GetSurfaceAt(surfaceID).TypeData.IsStop = 1;      % ������ surfaceID Ϊ����
        end
        
        function setWavelength(obj, wavelength)
            obj.TheApplication.PrimarySystem.SystemData.Wavelengths.GetWavelength(1).Wavelength = wavelength;
            obj.TheApplication.PrimarySystem.SystemData.Wavelengths.GetWavelength(1).MakePrimary;
        end
        
        function varargout = getMFE(obj,varargin)
            %getMFE - ��ȡ OpticStudio Zemax �����ۺ�����ֵ��
            %
            %	���ߣ�Tingyu Xue
            %	�������ڣ� 2021.7.24
            %	�����汾�� 1.0
            %     ���������� ��
            %
            %	�� MATLAB ���� ���ѽ��������� TheApplication ȫ�ֱ����� ZOSAPI_Application
            %   ����Ļ����ϣ����㲢���� Zemax ���ۺ�����ֵ�������������ʱ�����㲢������
            %   �ۺ������� 1 ���������ʱ������ĳ�е����ۺ���ֵ���ж���������ʱ�����ظ�
            %   �����ۺ�����
            %
            %   MFETable = getMFE();
            %   MFEValue = getMFE(rowNum);
            %   [MFEValue1, MFEValue2] = getMFE(rowNum1, rowNum2);
            %   ...

                TheApplication = obj.TheApplication;
                if isempty(TheApplication)
                    disp('δ�ҵ� ZOSAPI_Application ����');
                    return;
                elseif strcmp(class(TheApplication),'ZemaxUI.Common.ViewModels.ZOSAPI_Application')
                    N = TheApplication.PrimarySystem.MFE.NumberOfOperands;    % ���ۺ�������
                    TheMFE = TheApplication.PrimarySystem.MFE;
                    TheMFE.CalculateMeritFunction();                          % �������ۺ���
                    if nargin < 2          
                        for ii = 1: N
                            Type{ii,1} = char(TheApplication.PrimarySystem.MFE.GetOperandAt(ii).RowTypeName);
                            Target(ii,1) = TheApplication.PrimarySystem.MFE.GetOperandAt(ii).Target;
                            Weight(ii,1) = TheApplication.PrimarySystem.MFE.GetOperandAt(ii).Weight;
                            Value(ii,1) = TheApplication.PrimarySystem.MFE.GetOperandAt(ii).Value;
                        end
                        MFETable = table(Type,Target,Weight, Value);   % �������ۺ�����
                        varargout{1} = MFETable;
                    elseif nargin == 2
                        id = varargin{1};
                        if length(id) == 1
                            if id==fix(id) && id <= N && id > 0
                                varargout{1} = TheMFE.GetOperandAt(id).Value; % ���ص�id�����ۺ�����ֵ
                            else
                                disp('���ۺ�����Ŵ���');
                                return;
                            end
                        else
                            for i = 1:length(id)
                                if id(i)==fix(id(i)) && id(i) <= N && id(i) > 0
                                    varargout{i} = TheMFE.GetOperandAt(id(i)).Value;  % ���ص�id(i)�����ۺ�����ֵ
                                else
                                    disp('���ۺ�����Ŵ���');
                                    return;
                                end
                            end
                        end
                    end
                else
                    disp('�������ʹ���ȫ�ֱ��� TheApplication ��Ӧ���� ZOSAPI_Application ����! ');
                    return;
                end
        end
        
        function Surface = getSurface(obj,id)
            Surface = obj.LDE.GetSurfaceAt(id);
        end
        
        function NSCTrace(obj, FileName)
            % �����й���׷��
            File = obj.TheSystem.SystemFile;               % Zemax �ļ�·��
            obj.TheSystem.LoadFile(File, false);
            if ~isempty(obj.TheSystem.Tools.CurrentTool)
                obj.TheSystem.Tools.CurrentTool.Close();
            end
            NSCRayTrace = obj.TheSystem.Tools.OpenNSCRayTrace();
            NSCRayTrace.SplitNSCRays = true;
            NSCRayTrace.ScatterNSCRays = false;
            NSCRayTrace.UsePolarization = true;
            NSCRayTrace.IgnoreErrors = true;
            NSCRayTrace.SaveRays = true;
            NSCRayTrace.SaveRaysFile = FileName;
            NSCRayTrace.ClearDetectors(0);
            NSCRayTrace.RunAndWaitForCompletion();
            NSCRayTrace.Close();
        end
        
        function detectorData = getDetectorData(obj, DetectorID)
            ID = DetectorID;
            TheNCE = obj.NCE;
            data = NET.createArray('System.Double', TheNCE.GetDetectorSize(ID));
            TheNCE.GetAllDetectorData(ID, 1, TheNCE.GetDetectorSize(ID), data);
            [~, rows, cols] = TheNCE.GetDetectorDimensions(ID);
            detectorData = flipud(rot90(reshape(data.double, rows, cols)));
        end
        
        function plotDetector(obj, DetectorID)
            detectorData = obj.getDetectorData(DetectorID);
            figure('menubar', 'none', 'numbertitle', 'off');
            mesh(detectorData);
            xlabel('Column #');
            ylabel('Row #');
            view(0,90);
            axis equal;
            colorbar;
        end
        
        function Result = getZRDResult(obj, ZRDFilePath)
        % ��ȡ ZRD �ļ�
            if ~strcmp(ZRDFilePath(2),':')
                ZRDFilePath = fullfile(pwd, ZRDFilePath);
            end
            TheSystem = obj.TheSystem;
            if ~isempty(TheSystem.Tools.CurrentTool)
                TheSystem.Tools.CurrentTool.Close();
            end
            ZRDReader = TheSystem.Tools.OpenRayDatabaseReader();
            ZRDReader.ZRDFile = ZRDFilePath;
            ZRDReader.RunAndWaitForCompletion();
            if ZRDReader.Succeeded == 0
                disp('ZRD �ļ���ȡʧ��!');
                disp(ZRDReader.ErrorMessage);
            else
                disp('ZRD �ļ���ȡ�ɹ�!');
            end
            Result = ZRDReader.GetResults();
        end
        
        function makeVariable(obj,surfaceID, paraName)
            surface = obj.LDE.GetSurfaceAt(surfaceID);
            eval(['surface.SurfaceData.',paraName,'_Cell.MakeSolveVariable();']);
        end
        
        function makeFixed(obj, surfaceID, paraName)
            surface = obj.LDE.GetSurfaceAt(surfaceID);
            eval(['surface.SurfaceData.',paraName,'_Cell.MakeSolveFixed();']);
        end
    end
end