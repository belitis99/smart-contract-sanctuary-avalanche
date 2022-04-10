// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs9 is IHardwareSVGs, ICategories {
	function hardware_34() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Gavel',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h34-a" x1="6.5" x2="6.5" y1="22.13" y2="2.87"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h34-b" x1="10.5" x2="10.5" y1="24.78" y2="3.06"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h34-c" x1="5.13" x2="5.13" y1="3.3"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><filter id="h34-d" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient id="h34-e" x1="110" x2="110" xlink:href="#h34-c" y1="112.75" y2="91.25"/><radialGradient cx="109.91" cy="169.96" gradientUnits="userSpaceOnUse" id="h34-f" r="10.8"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.43" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><linearGradient id="h34-g" x1="106.28" x2="112.86" xlink:href="#h34-b" y1="145.34" y2="145.34"/><linearGradient id="h34-h" x1="88.2" x2="131.81" xlink:href="#h34-a" y1="189" y2="189"/><linearGradient gradientUnits="userSpaceOnUse" id="h34-i" x1="88.2" x2="131.81" y1="187" y2="187"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h34-j" x1="88.58" x2="126.48" xlink:href="#h34-b" y1="194.5" y2="194.5"/><symbol id="h34-k" viewBox="0 0 19 25"><rect fill="#231f20" height="19.25" width="3" x="16" y="2.87"/><path d="M11,4.69c-1.68,0-2-1.82-2-1.82H4c-2.21,0-4,4.31-4,9.63s1.79,9.63,4,9.63H9s.32-1.82,2-1.82,2,1.82,2,1.82V2.87S12.68,4.69,11,4.69Z" fill="url(#h34-a)"/><rect fill="#231f20" height="19.25" width="1" x="8" y="2.87"/><path d="M17,2V23a2,2,0,0,1-4,0V2a2,2,0,0,1,4,0ZM6,0A2,2,0,0,0,4,2V23a2,2,0,0,0,4,0V2A2,2,0,0,0,6,0Z" fill="url(#h34-b)"/></symbol><symbol id="h34-m" viewBox="0 0 10.25 3.3"><rect fill="url(#h34-c)" height="3.3" rx="1.65" width="10.25"/></symbol></defs><g filter="url(#h34-d)"><use height="25" transform="translate(84.71 89.5)" width="19" xlink:href="#h34-k"/><use height="25" transform="matrix(-1, 0, 0, 1, 135.29, 89.5)" width="19" xlink:href="#h34-k"/><rect fill="url(#h34-e)" height="21.5" width="14.57" x="102.71" y="91.25"/><path d="M110,172.4c-2.09,0-3.79.28-3.79,2.37,0,.85,2.79,6.11,3.79,6.11s3.79-5.27,3.79-6.11C113.79,172.68,112.09,172.4,110,172.4Z" fill="url(#h34-f)"/><path d="M111.93,128.07c0-4.74,2.54-7.16,1.46-11h-6.78c-1.08,3.86,1.46,6.28,1.46,11,0,4.22-1.86,34.28-1.86,40.73s7.58,6.45,7.58,0S111.93,132.29,111.93,128.07Z" fill="url(#h34-g)"/><rect fill="#231f20" height="1" width="8.35" x="105.82" y="112.75"/><rect fill="#231f20" height="1" width="7.16" x="106.42" y="117.05"/><rect fill="#231f20" height="1" width="4.39" x="107.81" y="132"/><use height="3.3" transform="translate(104.88 113.75)" width="10.25" xlink:href="#h34-m"/><use height="3.3" transform="translate(106.58 128.7) scale(0.67 1)" width="10.25" xlink:href="#h34-m"/></g><path d="M131.81,192H88.2v-2h43.61Zm-2.18-6H90.38v2h39.25Z" fill="url(#h34-h)"/><path d="M131.81,190H88.2l2.18-2h39.25Zm-4.36-6H92.56l-2.18,2h39.25Z" fill="url(#h34-i)"/><path d="M88.19,192a50.07,50.07,0,0,0,43.62,0Z" fill="url(#h34-j)"/>'
					)
				)
			);
	}

	function hardware_35() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Tongs and Hammer',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h35-a" x1="9.61" x2="19.45" y1="20.71" y2="73.46"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h35-b" x1="12.2" x2="12.2" y1="86.38" y2="0.03"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h35-c" x1="9.14" x2="9.14" y1="0.03" y2="86.41"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16470.41)" gradientUnits="userSpaceOnUse" id="h35-d" x1="7.87" x2="7.87" y1="16466.39" y2="16470.41"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h35-e" x1="23.64" x2="23.64" y1="85.88" y2="85.88"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h35-f" x1="17.33" x2="24.41" xlink:href="#h35-d" y1="16384.52" y2="16384.52"/><linearGradient id="h35-g" x1="8.38" x2="0" xlink:href="#h35-d" y1="16469.9" y2="16469.9"/><filter id="h35-h" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient id="h35-i" x1="131.53" x2="138.6" xlink:href="#h35-e" y1="130.95" y2="130.95"/><linearGradient gradientUnits="userSpaceOnUse" id="h35-j" x1="131.53" x2="138.6" y1="130.95" y2="130.95"><stop offset="0" stop-color="gray"/><stop offset="0.2" stop-color="#4b4b4b"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h35-k" x1="135.06" x2="135.06" xlink:href="#h35-d" y1="100.29" y2="100.3"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h35-l" x1="135.17" x2="135.17" xlink:href="#h35-d" y1="95.19" y2="105.89"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h35-m" x1="135.11" x2="135.11" xlink:href="#h35-d" y1="105.04" y2="95.95"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h35-n" x1="85" x2="85" y1="147.91" y2="144.09"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h35-o" x1="85" x2="85" xlink:href="#h35-n" y1="120.02" y2="115.41"/><symbol id="h35-p" viewBox="0 0 24.41 86.41"><path d="M17.67,85.88l-2.28-6a3.16,3.16,0,0,1-.31-1.38V37a4.31,4.31,0,0,0-1.26-3.05L1.48,21.58a3.26,3.26,0,0,1-.95-2.29V.53H7.85V3.8L6.55,5.1v11a4.27,4.27,0,0,0,1.26,3l12,12.05a3.23,3.23,0,0,1,.95,2.29V77.35a4.44,4.44,0,0,0,.26,1.48l2.58,7Z" fill="url(#h35-a)" stroke="url(#h35-b)" stroke-miterlimit="10"/><path d="M17.78,86.23l-2.39-6.32a3.16,3.16,0,0,1-.31-1.38V37a4.31,4.31,0,0,0-1.26-3.05L1.48,21.58a3.26,3.26,0,0,1-.95-2.29V0" fill="none" stroke="url(#h35-c)" stroke-miterlimit="10"/><path d="M7.35.53l1-.53V4l-1-.43Z" fill="url(#h35-d)"/><path d="M23.64,85.88" fill="none" stroke="url(#h35-e)" stroke-miterlimit="10"/><path d="M22.93,85.38l1.48,1H17.33l.65-1Z" fill="url(#h35-f)"/><path d="M1,1,0,0H8.38l-1,1Z" fill="url(#h35-g)"/></symbol></defs><g filter="url(#h35-h)"><path d="M137.22,168h-4.31l-1.38-1.6L135,162l3.6,4.44Zm0-74.17h-4.31l-1.38,1.6h7.07Z" fill="url(#h35-i)"/><rect fill="url(#h35-j)" height="70.96" width="7.07" x="131.53" y="95.47"/><polygon fill="url(#h35-k)" points="135.06 100.29 135.06 100.3 135.06 100.29 135.06 100.29"/><polygon fill="url(#h35-l)" points="121.1 95.94 121.1 105.05 135.06 105.89 149.25 104.07 149.25 97.03 136.54 95.19 121.1 95.94"/><polygon fill="url(#h35-m)" points="121.83 98.02 121.8 102.91 125.84 104.54 135.06 105.05 148.43 103.39 148.42 97.52 136.43 95.94 125.84 96.41 121.83 98.02"/><use height="86.41" transform="translate(76.16 95.86) scale(0.83)" width="24.41" xlink:href="#h35-p"/><path d="M86.07,123.11l.21-1,3.06-3.06,1-.45-.76-1.38-5.11,4.47Z"/><use height="86.41" transform="matrix(-0.83, 0, 0, 0.83, 93.84, 95.86)" width="24.41" xlink:href="#h35-p"/><path d="M85,119.52a1.81,1.81,0,1,0-1.8-1.81A1.8,1.8,0,0,0,85,119.52Z" fill="url(#h35-n)" stroke="url(#h35-o)" stroke-miterlimit="10"/><path d="M85,118.34a.63.63,0,0,0,0-1.25.63.63,0,1,0,0,1.25Z"/></g>'
					)
				)
			);
	}

	function hardware_36() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Pen Tool',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16394)" gradientUnits="userSpaceOnUse" id="h36-a" x1="1.82" x2="1.82" y1="16394" y2="16384"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h36-d" x1="8.18" x2="8.18" xlink:href="#h36-a" y1="16384" y2="16394"/><linearGradient id="h36-e" x1="10" x2="0" xlink:href="#h36-a" y1="16392.76" y2="16392.76"/><linearGradient id="h36-f" x1="0" x2="10" xlink:href="#h36-a" y1="16385.32" y2="16385.32"/><linearGradient id="h36-g" x1="5" x2="5" xlink:href="#h36-a" y1="16385" y2="16393"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 16439.1)" gradientUnits="userSpaceOnUse" id="h36-b" x1="1.77" x2="1.77" y1="16418.62" y2="16439.05"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h36-h" x1="2.52" x2="2.52" xlink:href="#h36-b" y1="16412.32" y2="16418.72"/><linearGradient id="h36-i" x1="1.19" x2="1.19" xlink:href="#h36-b" y1="16388.24" y2="16411.21"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h36-c" x1="110" x2="110" y1="79" y2="177"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(-1 0 0 1 220 0)" id="h36-l" x1="92.43" x2="127.58" xlink:href="#h36-c" y1="132.75" y2="132.75"/><linearGradient gradientTransform="rotate(180 110 132)" gradientUnits="userSpaceOnUse" id="h36-m" x1="93.43" x2="126.58" y1="133" y2="133"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><symbol id="h36-j" viewBox="0 0 10 10"><path d="m0 0 3.49 1.49.16 6.86L0 10Z" fill="url(#h36-a)"/><path d="M10 10 6.35 7.35l.16-5.86L10 0Z" fill="url(#h36-d)"/><path d="M10 0 7.51 2.49H2.5L0 0Z" fill="url(#h36-e)"/><path d="m0 10 2.65-2.65h4.7L10 10Z" fill="url(#h36-f)"/><path d="M9 9V1H1v8Z" fill="url(#h36-g)"/></symbol><symbol id="h36-n" viewBox="0 0 4.41 55.09"><path d="M.2 1c1.66 0 2.57 1.36 2.29 3.26L.62 20.67l1.02-.25L3.48 4.4a4.08 4.08 0 0 0-.79-3.33A3.23 3.23 0 0 0 .2 0a.73.73 0 0 0 0 1Z" fill="url(#h36-b)"/><path d="m1.67 20.13-1.05.54c1.63.87 2.83 2.2 2.79 3.68A3.03 3.03 0 0 1 .7 26.99l.83.97a3.7 3.7 0 0 0 2.88-3.58 5.1 5.1 0 0 0-2.74-4.25Z" fill="url(#h36-h)"/><path d="m1.7 49.56-1 5.53V27l1 .92Z" fill="url(#h36-i)"/></symbol><filter id="h36-k"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><path d="m105 191.45.05-3 9.95.05-.05 2.95Zm37.5-37.5.05-3 9.95.05-.05 2.95Zm-75 0 .05-3 9.95.05-.05 2.95Zm75-60 .05-2.96 9.95.05-.05 2.91Zm-75 0 .05-3 9.95.05-.05 2.95Z"/><path d="M147.5 88v60a37.5 37.5 0 0 1-75 0V88" fill="none" stroke="#000" stroke-miterlimit="10"/><path d="M147.37 147v20.62M72.5 147v20.62M110 184.5H89.38m20.49 0h20.61" fill="none" stroke="#000" stroke-miterlimit="10" stroke-width=".5"/><path d="M71.25 167.62a1.25 1.25 0 1 1 1.25 1.25 1.25 1.25 0 0 1-1.25-1.25Zm18.13 18.13a1.25 1.25 0 1 0-1.25-1.25 1.25 1.25 0 0 0 1.25 1.25Zm41.1 0a1.25 1.25 0 1 0-1.25-1.25 1.25 1.25 0 0 0 1.25 1.25Zm16.88-16.88a1.25 1.25 0 1 0-1.25-1.25 1.25 1.25 0 0 0 1.25 1.25Z"/><path d="M147.5 87v60a37.5 37.5 0 0 1-75 0V87" fill="none" stroke="url(#h36-c)" stroke-miterlimit="10"/><use height="10" transform="translate(142.5 82)" width="10" xlink:href="#h36-j"/><use height="10" transform="translate(142.5 142)" width="10" xlink:href="#h36-j"/><use height="10" transform="translate(105 179.5)" width="10" xlink:href="#h36-j"/><use height="10" transform="translate(67.5 82)" width="10" xlink:href="#h36-j"/><use height="10" transform="translate(67.5 142)" width="10" xlink:href="#h36-j"/><path d="M108.5 152.38h3v32h-3z"/><g filter="url(#h36-k)"><path d="M118.28 87.05V103c-2.17 1.32-3.36 2.54-3.32 4.41 0 4.43 12.6 10.2 12.62 22.07 0 15.98-11.78 21.7-16.34 50.95h-.74l.93-27.18 2.44-3.57-2.4-4.22c.7-7.75 1.18-18.46 1.18-18.46l-2.65-1.25-2.65 1.25s.48 10.7 1.17 18.46l-2.39 4.22 2.45 3.57.92 27.18h-.74c-4.56-29.25-16.33-34.97-16.33-50.95 0-11.87 12.62-17.64 12.62-22.07.03-1.87-1.16-3.09-3.33-4.41V87.05a18.37 18.37 0 0 1 16.57 0Z" fill="url(#h36-l)"/><path d="M110 125.75c-1.8 0-3.26 1.28-2.9 3.99.57 4.33.97 8 1.6 15.72a5.2 5.2 0 0 0-2.43 4.26c.06 1.82 2.61 3.53 2.61 3.53l-.3 22.1c-4.1-23.92-15.15-32.4-15.15-45.87 0-12.16 12.62-15.84 12.62-22.05.05-2.37-2.27-3.27-4.33-4.43V88.14a23.65 23.65 0 0 1 16.57 0V103c-2.06 1.17-4.37 2.06-4.33 4.43 0 6.22 12.62 9.89 12.62 22.05 0 13.47-11.04 21.96-15.15 45.87l-.3-22.1s2.56-1.71 2.61-3.53a5.2 5.2 0 0 0-2.42-4.25c.62-7.73 1.03-11.4 1.6-15.73.34-2.71-1.12-4-2.92-4Z" fill="url(#h36-m)"/><use height="55.09" transform="translate(109.8 125.33)" width="4.41" xlink:href="#h36-n"/><use height="55.09" transform="matrix(-1 0 0 1 110.2 125.33)" width="4.41" xlink:href="#h36-n"/></g>'
					)
				)
			);
	}

	function hardware_37() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Triskele',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h37-a" x1="22.29" x2="22.29" y1=".69" y2="56.98"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h37-c" x1="33.1" x2="49.73" xlink:href="#h37-a" y1="34.07" y2="26.11"/><linearGradient id="h37-d" x1="48.17" x2="48.17" xlink:href="#h37-a" y1="27.88" y2="6.83"/><linearGradient id="h37-e" x1="40.36" x2="40.36" xlink:href="#h37-a" y1="17.66" y2="0"/><linearGradient id="h37-b" x1="0" x2="42.75" xlink:href="#h37-a" y1="17.16" y2="17.16"/><symbol id="h37-h" viewBox="0 0 42.75 34.33"><path d="M3.26 34.33C-.55 16.86 11.43 7.58 27.47 10.28c9.12 5.4 15.27-3.83 15.28-5.56L39.15 0c0 4.64-2.1 8.11-6.54 8.11S27.62 4.4 18.69 4.4s-16.7 8.17-16.7 8.17C-3.13 24 3.26 34.33 3.26 34.33Z" fill="url(#h37-b)"/></symbol><symbol id="h37-i" viewBox="0 0 55.57 56.98"><path d="M4.92 56.98A25.4 25.4 0 0 1 3.64 35.2C6 12.23 25.3 4.45 33.22 4.45c7.55 0 8.07 6.34 7.56 8.33l3.8-5.16c-.41-6.9-10-8.58-19.42-5.32C17.23 4.78 0 15.25 0 37.99c0 11.94 4.92 18.99 4.92 18.99Z" fill="url(#h37-a)"/><path d="M55.57 17.66a12.36 12.36 0 0 1-11.8 10.13c-3.4 7.51-11.1 6.9-14.65 5.13 14.36 7.85 26.45-3.97 26.45-15.26Z" fill="url(#h37-c)"/><path d="m40.78 12.78 3-5.22c4.4-2.49 11.8 1.53 11.8 10.1a10.28 10.28 0 0 1-11.8 10.1l-2.98-5.11c3.99 3.57 11.25 1.5 11.25-5 0-7.05-7.92-8.36-11.27-4.87Z" fill="url(#h37-d)"/><path d="M25.15 2.29s14.04-5.34 18.64 5.27c9.08-.65 11.53 6.14 11.78 10.1C55.57.9 40.97-3.2 25.15 2.29Z" fill="url(#h37-e)"/></symbol><radialGradient cx=".5" cy=".2" id="h37-g" r="1"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset=".66" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></radialGradient><filter id="h37-f"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h37-f)"><path d="M110 106.05a41 41 0 1 0 41 41 41 41 0 0 0-41-41Zm0 76.77a35.76 35.76 0 1 1 35.76-35.76A35.76 35.76 0 0 1 110 182.82Z" fill="url(#h37-g)"/><use height="34.33" transform="translate(73.77 131.67)" width="42.75" xlink:href="#h37-h"/><use height="34.33" transform="rotate(120 35.1 102.52)" width="42.75" xlink:href="#h37-h"/><use height="34.33" transform="rotate(-120 111.12 59.93)" width="42.75" xlink:href="#h37-h"/><use height="56.98" transform="rotate(120 42.47 113.37)" width="55.57" xlink:href="#h37-i"/><use height="56.98" transform="translate(72.12 109.02)" width="55.57" xlink:href="#h37-i"/><use height="56.98" transform="rotate(-120 105.41 71.73)" width="55.57" xlink:href="#h37-i"/></g>'
					)
				)
			);
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
        string svgString;
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}