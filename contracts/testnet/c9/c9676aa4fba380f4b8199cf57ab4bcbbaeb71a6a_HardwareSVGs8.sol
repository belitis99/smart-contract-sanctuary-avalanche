// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs8 is IHardwareSVGs, ICategories {
	function hardware_30() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Horseshoe and Star',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h30-a" x1="4.78" x2="4.78" y1="8.77"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h30-b" x1="12.08" x2="12.08" xlink:href="#h30-a" y1="22.4" y2="11.69"/><linearGradient id="h30-c" x1="12.04" x2="12.04" xlink:href="#h30-a" y1="36.46" y2="25.57"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16404.16)" id="h30-d" x1="14.71" x2="-0.64" xlink:href="#h30-a" y1="16395.03" y2="16395.22"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16404.16)" id="h30-e" x1="-1.7" x2="14.38" xlink:href="#h30-a" y1="16392.91" y2="16392.95"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16404.16)" id="h30-f" x1="1.05" x2="7.99" xlink:href="#h30-a" y1="16394.91" y2="16401.73"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16404.16)" id="h30-g" x1="4.2" x2="4.2" xlink:href="#h30-a" y1="16394.39" y2="16382.02"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16404.16)" id="h30-h" x1="5.83" x2="1.26" xlink:href="#h30-a" y1="16385.46" y2="16393.01"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16404.16)" id="h30-i" x1="6.51" x2="0.49" xlink:href="#h30-a" y1="16403.31" y2="16395.96"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16403.83)" id="h30-j" x1="0.89" x2="1.88" xlink:href="#h30-a" y1="16382.25" y2="16400.12"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16403.83)" id="h30-k" x1="2.08" x2="3.61" xlink:href="#h30-a" y1="16398.85" y2="16385.06"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h30-l" x1="104.26" x2="109.71" xlink:href="#h30-a" y1="110.28" y2="103.69"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h30-m" x1="110" x2="110" xlink:href="#h30-a" y1="106.59" y2="90.3"/><filter id="h30-n" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientUnits="userSpaceOnUse" id="h30-o" x1="110" x2="110" y1="162" y2="87.18"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="translate(220 264) rotate(180)" id="h30-p" x1="110" x2="110" xlink:href="#h30-a" y1="105.97" y2="173.52"/><linearGradient gradientUnits="userSpaceOnUse" id="h30-q" x1="73.47" x2="146.53" y1="124.59" y2="124.59"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h30-r" x1="132.23" x2="132.23" xlink:href="#h30-a" y1="107.14" y2="109.88"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h30-s" x1="79.75" x2="79.75" xlink:href="#h30-a" y1="108.94" y2="111.62"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" id="h30-t" x1="140.25" x2="140.25" xlink:href="#h30-a" y1="108.94" y2="111.62"/><linearGradient gradientTransform="translate(220 264) rotate(180)" id="h30-u" x1="132.23" x2="132.23" xlink:href="#h30-a" y1="107.14" y2="109.88"/><linearGradient gradientTransform="translate(220 264) rotate(180)" id="h30-v" x1="140.25" x2="140.25" xlink:href="#h30-a" y1="108.94" y2="111.62"/><symbol id="h30-w" viewBox="0 0 4.56 19.83"><path d="M2.28,19.83V0L0,14.31H0Z" fill="url(#h30-j)"/><path d="M2.28,19.83l2.28-5.52L2.28,0Z" fill="url(#h30-k)"/></symbol><symbol id="h30-y" viewBox="0 0 15.2 20.16"><path d="M0,10.08H15.2L4.52,7.86Z" fill="url(#h30-d)"/><path d="M0,10.08,4.52,12.3,15.2,10.08Z" fill="url(#h30-e)"/><path d="M0,10.08,4.52,7.86,8.4,0,0,10.08Z" fill="url(#h30-f)"/><path d="M0,10.08,8.4,20.16,4.52,12.3Z" fill="url(#h30-g)"/><path d="M0,10.08,2.28,15.6,8.4,20.16Z" fill="url(#h30-h)"/><path d="M8.4,0,2.28,4.56,0,10.08Z" fill="url(#h30-i)"/></symbol><symbol id="h30-aa" viewBox="0 0 14.76 36.45"><path d="M6.91,7.78a38.93,38.93,0,0,0-5.8-5.21C-.3,1.51,1-.16,2.48.77A34.11,34.11,0,0,1,8.6,6.13C9.93,7.52,8.07,9.1,6.91,7.78Z" stroke="url(#h30-a)"/><path d="M11.75,21c-.16-.77-1.05-4.81-1.77-7.15a1.24,1.24,0,1,1,2.36-.77c.74,2.45,1.74,6.36,1.89,7.26C14.55,22.33,12,22.25,11.75,21Z" stroke="url(#h30-b)"/><path d="M10.11,34.35a71.8,71.8,0,0,0,1.46-7.07,1.25,1.25,0,1,1,2.45.4c-.42,2.5-.92,5-1.5,7.25C12.13,36.45,9.6,36.3,10.11,34.35Z" stroke="url(#h30-c)"/></symbol></defs><path d="M125.2,162l-10.68.28,3.88-10.36L110,162.59l-8.4-10.67,3.88,10.36L94.8,162h0l10.68,4.71-3.88,5.37,6.12-2.06L110,184.33,112.28,170l6.12,2.06-3.88-5.37L125.2,162Z"/><path d="M107.72,156.48l-6.12-4.56L110,162Z" fill="url(#h30-l)"/><use height="19.83" transform="translate(107.72 142.17)" width="4.56" xlink:href="#h30-w"/><use height="19.83" transform="matrix(1, 0, 0, -1, 107.72, 181.83)" width="4.56" xlink:href="#h30-w"/><use height="20.16" transform="translate(110 151.92)" width="15.2" xlink:href="#h30-y"/><use height="20.16" transform="matrix(-1, 0, 0, 1, 110, 151.92)" width="15.2" xlink:href="#h30-y"/><path d="M116.51,162l-4.57-.95,1.66-3.37L111,159.63l-1-6.13-1,6.13h0l-2.62-1.95,1.66,3.37-4.58.95h0l4.58.95-1.66,3.37,2.62-1.95,1,6.13,1-6.13,2.63,1.95L111.94,163l4.57-.95Z" fill="url(#h30-m)"/><g filter="url(#h30-n)"><path d="M147.64,121.6c0-15.22-11.16-34.42-37.64-34.42s-37.64,19.2-37.64,34.42c0,14.06,6.44,24.23,9.23,32.06l-5.41-1.21V162H90.71v-4c0-10.71-4.87-18.33-4.87-32.7,0-14.74,12.24-22.11,24.16-22.11s24.16,7.37,24.16,22.11c0,14.37-4.87,22-4.87,32.7v4h14.53v-9.55l-5.41,1.21C141.2,145.83,147.64,135.66,147.64,121.6Z" fill="url(#h30-o)"/><path d="M110,101.76c12.61,0,25.55,8.34,25.55,25,0,16.27-5.15,20.53-5.15,31.24l4.77-3c1.12-3.27,10-19.34,10-33.43,0-12.36-5.9-26.5-23.83-31.12,0,0-2,5.77-11.35,5.77s-11.35-5.77-11.35-5.77C80.72,95.1,74.82,109.24,74.82,121.6c0,14.09,8.89,30.16,10,33.43l4.77,3c0-10.71-5.15-15-5.15-31.24C84.45,110.1,97.39,101.76,110,101.76Z" fill="url(#h30-p)"/><path d="M137.36,153.29c.69-1.95,1.61-4,2.58-6.26,2.94-6.7,6.59-15,6.59-25.43,0-13.39-9.73-33.3-36.53-33.3s-36.53,19.91-36.53,33.3c0,10.39,3.66,18.73,6.59,25.43,1,2.22,1.89,4.31,2.58,6.26l.68,1.9-6-1.35v7H89.6V157l-4.77-2-.16-.48c-.2-.59-.72-1.7-1.38-3.12-2.75-5.93-8.47-18.27-8.47-29.83,0-11.06,5.64-24.72,21.47-29.91a3.1,3.1,0,0,1,2.86.75c1,1.15,4.15,3.82,10.85,3.82s9.82-2.67,10.85-3.82a2.8,2.8,0,0,1,2.87-.75c15.82,5.19,21.46,18.85,21.46,29.91,0,11.56-5.72,23.9-8.47,29.83-.66,1.42-1.18,2.53-1.38,3.12l-.16.48-4.77,2v3.89h12.3v-7l-6,1.35Z" fill="url(#h30-q)"/><path d="M130.4,157l-1.11-.75,5-2.05.9.84Z" fill="url(#h30-r)"/><path d="M83.32,155.19l-1.73-1.53-5.41-1.21,1.12,1.39Z" fill="url(#h30-s)"/><use height="36.46" transform="translate(127.2 98.47)" width="14.76" xlink:href="#h30-aa"/><use height="36.46" transform="matrix(-1, 0, 0, 1, 92.8, 98.47)" width="14.76" xlink:href="#h30-aa"/><path d="M136.68,155.19l1.73-1.53,5.41-1.21-1.12,1.39Z" fill="url(#h30-t)"/><path d="M89.6,157l1.11-.75-5-2.05-.9.84Z" fill="url(#h30-u)"/><path d="M83.32,155.19l-1.73-1.53-5.41-1.21,1.12,1.39Z" fill="url(#h30-v)"/></g>'
					)
				)
			);
	}

	function hardware_31() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Lug Wrench and Four Lug Nuts',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h31-a" x1="35.993" x2="35.993" y1="14"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h31-b" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 16395.17)" gradientUnits="userSpaceOnUse" id="h31-d" x1="5.294" x2="5.294" y1="16393.933" y2="16386.058"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><symbol id="h31-f" viewBox="0 0 71.987 14"><path d="m5.994 14 6.878-4.821V4.82L5.994 0H1L0 1v12l1 1Zm64.993 0 1-1V1l-1-1h-4.994l-6.878 4.821V9.18L65.993 14Z" fill="url(#h31-a)"/><path d="M10.987 3.5h50v7h-50Z" fill="url(#h31-b)"/><path d="M5.993 14H1V0h4.993ZM70.987 0h-4.994v14h4.994Z" fill="url(#h31-b)"/></symbol><symbol id="h31-g" viewBox="0 0 10.589 11.17"><path d="M10.589 4.585H0v2l2.647 4.585h5.294l2.648-4.585Z"/><path d="M7.941 0H2.647L0 4.585 2.647 9.17h5.294l2.647-4.585Z" fill="url(#h31-c)"/><path d="M5.294 8.295a3.71 3.71 0 1 0-3.71-3.71 3.71 3.71 0 0 0 3.71 3.71Z" fill="url(#h31-d)"/></symbol><radialGradient cx="7348.186" cy="9068.331" gradientTransform="matrix(11.0498 0 0 -11.0498 -81190.69 100204.28)" gradientUnits="userSpaceOnUse" id="h31-c" r="1"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".55" stop-color="#fff"/></radialGradient><filter id="h31-e"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h31-e)"><use height="14" transform="rotate(-90 135.494 32.5)" width="71.987" xlink:href="#h31-f"/><path d="M104.122 131.993h-.116c0 .402.04.34.116 0Z"/><path d="M106.496 138.197a5.36 5.36 0 0 1 7.008 0l.03-7.304h-7.068Z"/><path d="M116.006 131.993h-.118c.077.342.118.405.118 0Z"/><use height="14" transform="translate(74.001 125)" width="71.987" xlink:href="#h31-f"/></g><use height="11.17" transform="translate(79.706 97.415)" width="10.589" xlink:href="#h31-g"/><use height="11.17" transform="translate(129.706 97.415)" width="10.589" xlink:href="#h31-g"/><use height="11.17" transform="translate(79.706 157.415)" width="10.589" xlink:href="#h31-g"/><use height="11.17" transform="translate(129.706 157.415)" width="10.589" xlink:href="#h31-g"/>'
					)
				)
			);
	}

	function hardware_32() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Masonry Trowel and Brickwork',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h32-a" x1="4.69" x2="11.98" y1="11.31" y2="-1.31"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h32-d" x1="8.33" x2="8.33" xlink:href="#h32-a" y1="10" y2="0"/><linearGradient id="h32-e" x1="8.33" x2="8.33" xlink:href="#h32-a" y1="0" y2="10"/><linearGradient gradientTransform="translate(-29.5 -29.5)" id="h32-g" x1="58.66" x2="58.66" xlink:href="#h32-a" y1="29.5" y2="90.59"/><linearGradient gradientTransform="matrix(-1 0 0 1 16452.39 -29.5)" id="h32-h" x1="16442.66" x2="16442.66" xlink:href="#h32-a" y1="90.59" y2="29.5"/><linearGradient gradientUnits="userSpaceOnUse" id="h32-c" x1="108.01" x2="111.72" y1="137.66" y2="137.66"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 -376.19 -197.15)" gradientUnits="userSpaceOnUse" id="h32-b" x1="486.18" x2="486.18" y1="-344.7" y2="-380.39"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 -376.19 -197.15)" id="h32-l" x1="486.15" x2="486.15" xlink:href="#h32-a" y1="-344.7" y2="-380.39"/><linearGradient gradientTransform="matrix(1 0 0 -1 -285.5 -111.5)" id="h32-m" x1="392.33" x2="398.65" xlink:href="#h32-b" y1="-294.37" y2="-294.37"/><linearGradient id="h32-n" x1="106.88" x2="112.38" xlink:href="#h32-c" y1="162.82" y2="162.82"/><symbol id="h32-f" viewBox="0 0 16.67 10"><path d="M.87 9.1V.9H15.8v8.2H.87z" fill="url(#h32-a)"/><path d="M.85 1 0 0h16.67l-.85 1Zm0 8L0 10h16.67l-.85-1Z" fill="url(#h32-d)"/><path d="M0 10V0l1 1v8Zm16.67 0V0l-1 1v8Z" fill="url(#h32-e)"/></symbol><symbol id="h32-j" viewBox="0 0 33.28 20"><use height="10" transform="translate(0 13.33) scale(.6667)" width="16.67" xlink:href="#h32-f"/><use height="10" transform="translate(11.09 13.33) scale(.6667)" width="16.67" xlink:href="#h32-f"/><use height="10" transform="translate(22.17 13.33) scale(.6667)" width="16.67" xlink:href="#h32-f"/><use height="10" transform="translate(5.54 6.67) scale(.6667)" width="16.67" xlink:href="#h32-f"/><use height="10" transform="translate(16.63 6.67) scale(.6667)" width="16.67" xlink:href="#h32-f"/><use height="10" transform="translate(11.09) scale(.6667)" width="16.67" xlink:href="#h32-f"/></symbol><symbol id="h32-k" viewBox="0 0 38.89 61.09"><path d="M19.44 0c8 14.02 16.32 38.25 19.45 54.04 0 0-9.32 5.56-19.45 7.05" fill="url(#h32-g)"/><path d="M19.44 61.1C9.32 59.6 0 54.03 0 54.03 3.13 38.25 11.44 14.02 19.44 0" fill="url(#h32-h)"/></symbol><filter id="h32-i"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h32-i)"><use height="20" transform="translate(68.36 142)" width="33.28" xlink:href="#h32-j"/><use height="20" transform="translate(118.36 142)" width="33.28" xlink:href="#h32-j"/><use height="61.09" transform="translate(90.56 77.95)" width="38.89" xlink:href="#h32-k"/><use height="61.09" transform="matrix(-.9508 0 0 .9634 128.49 80.47)" width="38.89" xlink:href="#h32-k"/><path d="M111.7 145.62V132h-.06a10.67 10.67 0 0 0-1.68-6.2 10.67 10.67 0 0 0-1.68 6.2v13.62h-1.45v3.9h6.32v-3.9Z" fill="url(#h32-c)"/><path d="M112.37 158.95c0-4.58 3.06-8.32.78-11.4h-6.32c-2.28 3.1.79 6.85.79 11.4s-2.66 6.35-2.66 14 3.26 10.29 5.03 10.29 5.03-2.62 5.03-10.28-2.65-9.43-2.65-14Z" fill="url(#h32-b)"/><path d="M110.94 158.95c0-4.58 1.26-8.32.32-11.4h-2.6c-.95 3.1.32 6.85.32 11.4s-1.09 6.35-1.09 14 1.34 10.29 2.07 10.29 2.07-2.62 2.07-10.28-1.09-9.43-1.09-14Z" fill="url(#h32-l)"/><path d="M112.37 183.82h-4.75l-.79-.95 3.17-.95 3.16.95-.79.95z" fill="url(#h32-m)"/><path d="M107.62 142.77h4.75v2.85h-4.75Zm-.8 40.1h6.33v-1.9h-6.32Z" fill="url(#h32-n)"/></g>'
					)
				)
			);
	}

	function hardware_33() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Rudder',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h33-a" x1="5.26" x2="3.08" y1="6.1" y2="4.26"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><filter id="h33-b" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h33-c" x1="118.28" x2="118.28" y1="102" y2="169.79"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h33-d" x1="106.56" x2="119.5" y1="156.17" y2="121.23"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 264)" gradientUnits="userSpaceOnUse" id="h33-e" x1="72.42" x2="149.8" y1="165.89" y2="165.89"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h33-f" x1="125.9" x2="104.39" xlink:href="#h33-d" y1="110.78" y2="147.41"/><linearGradient id="h33-g" x1="87.83" x2="117.23" xlink:href="#h33-d" y1="96.64" y2="100.84"/><symbol id="h33-h" viewBox="0 0 10.56 9.79"><path d="M4.78,6,1.93,9.39a1.09,1.09,0,0,1-1.54.14h0A1.09,1.09,0,0,1,.25,8L6.92,0l3.64,3L6.75,7.61Z" fill="url(#h33-a)"/></symbol></defs><g filter="url(#h33-b)"><path d="M149.8,94.21l-10.66,5.58L86.77,159.88a33.41,33.41,0,0,0,12,2.12c12,0,26.79-4.83,30.59-15L135,132l-5.12-9.42a4.79,4.79,0,0,1,.55-5.37Z" fill="url(#h33-c)"/><path d="M86.77,159.88,135,102l8.36-4.42-15,18.09c-1.55,1.84-.53,5.27.61,7.38l4.9,9-5.43,14.57C121.92,164.22,90.09,161,86.77,159.88Z" fill="url(#h33-d)"/><path d="M149.8,94.21,76.49,97.76,72.42,102H135l8.36-4.42Z" fill="url(#h33-e)"/><use height="9.78" transform="translate(99.44 129.03)" width="10.56" xlink:href="#h33-h"/><use height="9.78" transform="translate(88.9 141.68)" width="10.56" xlink:href="#h33-h"/><path d="M135,102,86.77,159.88c12.5-6,39.19-41.48,57.45-62.75Z" fill="url(#h33-f)"/><path d="M86.88,99.34c-7.74.42-10,.63-14.46,2.66H135l9.22-4.87S94.63,98.93,86.88,99.34Z" fill="url(#h33-g)"/></g>'
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