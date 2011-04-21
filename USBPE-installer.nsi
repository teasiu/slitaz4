##神雕teasiu开源大礼，作者 teasiu@163.com
##让菜鸟都可以制作自己的软件
##您可以任意修改本代码，但是请保留原作者信息。
##

!define NAME "PE2USB"
!define DISTRO "WINPE"
!define FILENAME "PE2USB"
!define VERSION "0.1"
!define MUI_ICON "usb48.ico"
RequestExecutionLevel highest ;设置用户最高权限
SetCompressor LZMA  ;压缩格式
CRCCheck On
XPStyle on  ;如果xp系统使用时，适应xp的风格
ShowInstDetails show
BrandingText "USBPE通用安装器 神雕teasiu作品"
CompletedText "安装结束，欢迎使用和收藏本工具!  --神雕teasiu"

InstallButtonText "创 建" ;将先一步按钮改名为创建

Name "${NAME} ${VERSION}"
OutFile "${FILENAME} ${VERSION}.exe"    ;生成的exe文件名

!include "nsDialogs.nsh"
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "WordFunc.nsh" ;磁盘列表
; 页面头设置
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "usb-logo2.bmp"
!define MUI_HEADERIMAGE_BITMAP_NOSTRETCH
!define MUI_HEADERIMAGE_RIGHT   ;右边显示logo图标，左边则改为LEFT

; 定义各项变量
Var DestDriveTxt
Var DestDrive
Var DestDisk
Var LabelDrivePageText
Var LabelDriveSelect
Var Format
Var FormatMe
Var Hddmode  ;在这个例子里我换成了syslinux模式
Var Zipmode  ;在这个例子里我换成了grub4dos模式
Var HddmodeMe
Var ZipmodeMe
Var Warning
Var Soft
Var Link
Var Links
Var Image
Var hImage
Var Iso
Var ISOFileTxt
Var ISOSelection
Var TheISO
Var ISOTest
Var ISOFile
var BootDir


Page custom drivePage  ;只定义了一页


!define MUI_INSTFILESPAGE_COLORS "00FF00 000000"
; Instfiles page
!define MUI_TEXT_INSTALLING_TITLE $(Install_Title)
!define MUI_TEXT_INSTALLING_SUBTITLE $(Install_SubTitle)
!define MUI_TEXT_FINISH_SUBTITLE $(Install_Finish_Sucess)
!insertmacro MUI_PAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "SimpChinese"  ;仅支持中文
LangString DrivePage_Title ${LANG_SIMPCHINESE} "【PE2USB】USB通用PE安装器"
LangString DrivePage_Title2 ${LANG_SIMPCHINESE} "先插入一个USB盘，然后再打开本软件进行安装."
LangString DrivePage_Text ${LANG_SIMPCHINESE} "本工具将使您的U盘完美启动."
LangString DrivePage_Input ${LANG_SIMPCHINESE} "第一步：点击下拉菜单选择您的U盘"
LangString Soft_Text ${LANG_SIMPCHINESE} "第二步：选择您的ISO内置的启动引导模式。必选。"
LangString Iso_Text ${LANG_SIMPCHINESE} "第三步：选择您的ISO镜像文件。"
LangString WarningPage_Text ${LANG_SIMPCHINESE} "注意：请确保U盘资料已备份。原资料将被完全覆写并不可恢复！"
LangString Creation ${LANG_SIMPCHINESE} "创建启动和解压ISO镜像文件到U盘，请稍后"
LangString Install_Title ${LANG_SIMPCHINESE} "安装中 ${DISTRO}"
LangString Install_SubTitle ${LANG_SIMPCHINESE} "请稍后 ${NAME} 安装 ${DISTRO} 到 $DestDisk"
LangString Install_Finish_Sucess ${LANG_SIMPCHINESE} "$\t ${NAME} 已经完成安装${DISTRO}到$DestDisk"
LangString IsoFile ${LANG_SIMPCHINESE} "ISO镜像文件|*.iso"
LangString Syslinux_Warning ${LANG_SIMPCHINESE} "一个错误 ($R8) 发生在当安装syslinux时.$\r$\n您的USB驱动器将不可启动..$\r$\n建议您更换U盘或格式化该盘后再试一次。"
LangString grub4dos_Warning ${LANG_SIMPCHINESE} "一个错误 ($R8) 发生在当安装grub4dos时.$\r$\n您的USB驱动器将不可启动..$\r$\n建议您更换U盘或格式化该盘后再试一次。"

Function .onInit
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"    ;开始时将所有资源调进临时文件夹以便后面直接调用
  File /r "src\*.*"
FunctionEnd

Function drivePage
  !insertmacro MUI_HEADER_TEXT $(DrivePage_Title) $(DrivePage_Title2)
  nsDialogs::Create 1018
  ${If} $DestDrive == ""
  GetDlgItem $6 $HWNDPARENT 1 ; 控制下一步的句柄
  EnableWindow $6 0 ; 关闭下一步按钮
  ${EndIf}
  ; 创建bmp广告位图
	${NSD_CreateBitmap} 75% 0 20% 100% ""
	Pop $Image
	${NSD_SetImage} $Image $PLUGINSDIR\ad.bmp $hImage
	
  ${NSD_CreateLabel} 0 0 70% 30 $(DrivePage_Text)
  Pop $LabelDrivePageText
  ${NSD_CreateLabel} 0 20 70% 15 $(DrivePage_Input)
  Pop $LabelDriveSelect
  SetCtlColors $LabelDriveSelect /Branding 0000BD  ; 蓝色字体
  
  ;创建下拉菜单
  ${NSD_CreateDroplist} 0 40 30% 25 ""
  Pop $DestDriveTxt
  ${NSD_OnChange} $DestDriveTxt db_select.onchange
  ${GetDrives} "FDD" driveList  ;FDD表示仅显示移动磁盘即U盘, HDD表示显示本地磁盘即硬盘, ALL表示显示所有磁盘
  ${If} $DestDrive != ""
  ${NSD_CB_SelectString} $DestDriveTxt $DestDrive
  ${EndIf}

; 增加帮助或更新网址链接
  ${NSD_CreateLink} 85% 190 15% 14 "软件更新"
  Pop $Link
  ${NSD_OnClick} $Link onClickMyLink
; 格式化选项
  ${NSD_CreateButton} 32% 38 38% 22 "(可选)FAT32格式化此U盘"
  Pop $Format
  ${NSD_OnClick} $Format FormatIt
; 说明文字
  ${NSD_CreateLabel} 0 70 70% 15 $(Soft_Text) ;软件内容,括号里面是调回上面的中文文字
  Pop $Soft
  SetCtlColors $Soft /Branding 0000BD ;蓝色
  
  ${NSD_CreateLabel} 0 115 70% 15 $(Iso_Text) ;内容
  Pop $Iso
  SetCtlColors $Iso /Branding 0000BD ;蓝色
  
  ${NSD_CreateText} 0 135 50% 20 "浏览已下载的*.iso文档并选择"
  Pop $ISOFileTxt

  ${NSD_CreateBrowseButton} 53% 135 65 20 "浏览"
  Pop $ISOSelection
  ${NSD_OnClick} $ISOSelection ISOBrowse

; 磁盘启动模式选项
  ${NSD_CreateCheckBox} 0 90 36% 15 "Syslinux启动模式."
  Pop $Hddmode
  ${NSD_Check} $Hddmode ; 默认此项打钩
  ${NSD_OnClick} $Hddmode HddmodeIt

  ${NSD_CreateCheckBox} 38% 90 36% 15 "Grub4dos启动模式."
  Pop $Zipmode
  ${NSD_OnClick} $Zipmode ZipmodeIt

; 警示标签
  ${NSD_CreateLabel} 0 190 80% 14 $(WarningPage_Text)
  Pop $Warning
  EnableWindow $Format 0   ;关闭提示
  EnableWindow $Hddmode 0
  EnableWindow $Zipmode 0
  EnableWindow $ISOFileTxt 0
  EnableWindow $ISOSelection 0
  ShowWindow $Warning 0
  GetDlgItem $6 $HWNDPARENT 3
  ShowWindow $6 0 ; 屏蔽回去
  nsDialogs::Show
  ${NSD_FreeImage} $hImage  ; 释放位图
FunctionEnd

Function ISOBrowse
 nsDialogs::SelectFileDialog open "$EXEDIR" $(IsoFile) ;如果软件同目录里有ISO文键，自动选择
 Pop $TheISO
 ${NSD_SetText} $ISOFileTxt $TheISO
 SetCtlColors $ISOFileTxt 009900 FFFFFF
 StrCpy $ISOTest "$TheISO"
 StrCpy $ISOFile "$TheISO" ; 定义选择的镜像文件为ISOFile，以便后面解压
 ${NSD_SetText} $Iso "第三步完成，您的ISO镜像文件已选择."
 ${NSD_CreateLabel} 0 165 75% 14 "OK，点击创建即可"
  GetDlgItem $6 $HWNDPARENT 1 ; 控制下一步的句柄
  EnableWindow $6 1 ; 打开下一步按钮
FunctionEnd

Function onClickMyLink
  Pop $Links ; 为了避免错误，pop定量
  ExecShell "open" "http://www.ecoo168.com"
FunctionEnd


Function db_select.onchange
  Pop $DestDriveTxt
  ${NSD_GetText} $DestDriveTxt $0
  StrCpy $DestDrive "$0"
  StrCpy $DestDisk "$DestDrive" -1
  EnableWindow $Format 1  ;打开提示
  EnableWindow $Hddmode 1
  EnableWindow $Zipmode 1
  EnableWindow $ISOFileTxt 1
  EnableWindow $ISOSelection 1
  ShowWindow $Warning 1
  SetCtlColors $Warning /Branding FF0000
  Call HddmodeIt
  Call ZipmodeIt
FunctionEnd

;盘符列表方程
Function driveList
	SendMessage $DestDriveTxt ${CB_ADDSTRING} 0 "STR:$9"
	Push 1
FunctionEnd

Function HddmodeIt
  ${NSD_GetState} $Hddmode $HddmodeMe
  
  ${If} $HddmodeMe == ${BST_CHECKED}
  ${NSD_Check} $Hddmode
  StrCpy $HddmodeMe "Yes"
  ${NSD_SetText} $Hddmode "(已选)Syslinux启动模式"
  ${NSD_Uncheck} $Zipmode
  StrCpy $ZipmodeMe "No"
  ${NSD_SetText} $Zipmode "Grub4dos启动模式"
  
  ${ElseIf} $HddmodeMe == ${BST_UNCHECKED}
  ${NSD_Uncheck} $Hddmode
  StrCpy $HddmodeMe "No"
  ${NSD_SetText} $Hddmode "Syslinux启动模式"
  ${NSD_Check} $Zipmode
  StrCpy $ZipmodeMe "Yes"
  ${NSD_SetText} $Zipmode "(已选)Grub4dos启动模式"
  ${EndIf}
FunctionEnd

Function ZipmodeIt ; Set Format2 Option
  ${NSD_GetState} $Zipmode $ZipmodeMe
  ${If} $ZipmodeMe == ${BST_CHECKED}
  ${NSD_Check} $Zipmode
  StrCpy $ZipmodeMe "Yes"
  ${NSD_SetText} $Zipmode "(已选)Grub4dos启动模式"
  ${NSD_Uncheck} $Hddmode
  StrCpy $HddmodeMe "No"
  ${NSD_SetText} $Hddmode "Syslinux启动模式"
  ${ElseIf} $ZipmodeMe == ${BST_UNCHECKED}
  ${NSD_Uncheck} $Zipmode
  StrCpy $ZipmodeMe "No"
  ${NSD_SetText} $Zipmode "Grub4dos启动模式"
  ${NSD_Check} $Hddmode
  StrCpy $HddmodeMe "Yes"
  ${NSD_SetText} $Hddmode "(已选)Syslinux启动模式"
  ${EndIf}
FunctionEnd

Function FormatIt ; 设置格式化配置
  Pop $FormatMe
  MessageBox MB_YESNO "格式化U盘可以取回全部空间，继续吗？" IDYES true IDNO false
true:
  Goto next
false:
  MessageBox MB_OK|MB_ICONSTOP "不格式化，退出"
  Abort
next:
  MessageBox MB_YESNO "真的格式化吗？(请确保您的U盘资料已经备份,格式化将擦除U盘资料且不可恢复)" /SD IDYES IDNO false2
  Goto next2
false2:
  MessageBox MB_OK|MB_ICONSTOP "不格式化，退出"
  Abort
next2:  ;这是fbinst的格式化dos命令，详细请参考fbinst的官方说明, fbinst命令支持盘符c:的表示形式和hd0,hd1的表示形式
  nsExec::ExecToLog '"cmd" /c "echo y|$PLUGINSDIR\fbinst $DestDisk format --raw --force --fat32"'
  MessageBox MB_OK "格式化完成，恢复U盘全部空间。"
FunctionEnd

Function InstallEYes
  SetShellVarContext all
  StrCpy $R0 $DestDrive -1 ; 将盘符后面的'\'字符截去，表示为如D: 再定义为$R0
  ClearErrors
  ${If} $HddmodeMe == "Yes"
    DetailPrint "创建syslinux的引导到 $DestDisk, 请稍后"
   	ExecWait '$PLUGINSDIR\syslinux.exe -maf $R0' $R8   ; 这是syslinux的dos命令行，详情请参考官方说明
  	DetailPrint "Syslinux安装返回信息检测值=$R8 , 0表示成功"
    Banner::destroy
	${If} $R8 != 0  ; 如果返回值不是0，则弹出警告提示框
    MessageBox MB_ICONEXCLAMATION|MB_OK $(Syslinux_Warning)
    DetailPrint "请更换u盘或格式化后再试一次。"
  ${EndIf}
  Call syscopyfile
  ${ElseIf} $ZipmodeMe == "Yes"
  DetailPrint "创建Grub4dos启动模式的引导到 $DestDisk, 请稍后"
	ExecWait '$PLUGINSDIR\BOOTICE.EXE /DEVICE=$R0 /mbr /install /type=grub4dos /auto' $R8  ; bootice支持的命令行，有很多用法，参考官方
	DetailPrint "Grub4dos安装返回信息检测值=$R8 , 0表示成功"
	Banner::destroy
	${If} $R8 != 0 ; 如果返回值不是0，则弹出警告提示框
  MessageBox MB_ICONEXCLAMATION|MB_OK $(grub4dos_Warning)
  DetailPrint "请更换u盘或格式化后再试一次。"
  ${EndIf}
  Call grubcopyfile
  ${EndIf}
FunctionEnd

Function syscopyfile

  ${If} ${FileExists} "$BootDir\syslinux.cfg"
	;什么也不做
  ${ElseIf} ${FileExists} "$BootDir\syslinux\syslinux.cfg"
  ;什么也不做
  ${ElseIf} ${FileExists} "$BootDir\boot\syslinux\syslinux.cfg"
  ;什么也不做
	${ElseIf} ${FileExists} "$BootDir\boot\isolinux\isolinux.cfg"
  Rename "$BootDir\boot\isolinux\" "$BootDir\boot\syslinux\"
  Rename "$BootDir\boot\syslinux\isolinux.cfg" "$BootDir\boot\syslinux\syslinux.cfg"
	${ElseIf} ${FileExists} "$BootDir\isolinux\isolinux.cfg"
	Rename "$BootDir\isolinux\" "$BootDir\syslinux\"
  Rename "$BootDir\syslinux\isolinux.cfg" "$BootDir\syslinux\syslinux.cfg"
  ${ElseIf} ${FileExists} "$BootDir\isolinux.cfg"
  Rename "$BootDir\isolinux.cfg" "$BootDir\syslinux.cfg"
	${Else} ; 上面的文件都没有时
	DetailPrint "没有找到syslinux标准配置文件syslinux.cfg"
	DetailPrint "可能是您安装的ISO不是使用syslinux引导，"
	DetailPrint "或者是引导文件被修改为其他名字使我无法识别,"
	DetailPrint "请尝试其他启动方式或者手动寻找并编辑引导文件。"
	${EndIf}
	; 继续检测syslinux的图形菜单,以达到版本一致
	${If} ${FileExists} "$BootDir\vesamenu.c32"
	CopyFiles "$PLUGINSDIR\vesamenu.c32" "$BootDir\vesamenu.c32"
	${ElseIf} ${FileExists} "$BootDir\syslinux\vesamenu.c32"
  CopyFiles "$PLUGINSDIR\vesamenu.c32" "$BootDir\syslinux\vesamenu.c32"
	${ElseIf} ${FileExists} "$BootDir\boot\syslinux\vesamenu.c32"
  CopyFiles "$PLUGINSDIR\vesamenu.c32" "$BootDir\boot\syslinux\vesamenu.c32"
	${EndIf}
FunctionEnd

Function grubcopyfile
;如果要拷贝文件进去，请在资源包里增加相应文件，拷贝命令如下
#  CopyFiles "$PLUGINSDIR\grldr" "$BootDir\grldr"
#  CopyFiles "$PLUGINSDIR\menu.lst" "$BootDir\menu.lst"
  
  ${If} ${FileExists} "$BootDir\grldr"
  ${ElseIf} ${FileExists} "$BootDir\grub\grldr"
  ${ElseIf} ${FileExists} "$BootDir\boot\grub\grldr"
  ${ElseIf} ${FileExists} "$BootDir\grub.exe"
  ${ElseIf} ${FileExists} "$BootDir\boot\grub.exe"
  ${ElseIf} ${FileExists} "$BootDir\boot\grub\grub.exe"
  ${Else} ; 如果上述任一文件都没有,显示以下提示
	DetailPrint "没有找到grub4dos标准配置文件grldr。"
	DetailPrint "可能是您安装的ISO不是使用grub4dos引导，"
	DetailPrint "或者是引导文件被修改为其他名字使我无法识别,"
	DetailPrint "请尝试其他启动方式或者手动寻找并编辑引导文件。"
	${EndIf}
FunctionEnd

Section "Install" main
  StrCpy $BootDir $DestDrive -1 ; 将盘符后面的'\'字符截去，表示为如D: 再定义为bootdir
  StrCpy $BootDir "$BootDir"
  DetailPrint $(Creation)
  ExecWait '"$PLUGINSDIR\7zG.exe" x "$ISOFile" -o"$BootDir" -y -x![BOOT]*' ;这是内置7z自动解压ISO镜像文件到磁盘
  DetailPrint "正在检测和配置标准启动文件，请稍后"
  Call InstallEYes

SectionEnd
