// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs11 is IHardwareSVGs, ICategories {
	function hardware_42() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Scales',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(1 0 0 -1 0 16425.33)" gradientUnits="userSpaceOnUse" id="h42-a" x1="14.29" x2="14.29" y1="16419.05" y2="16425.33"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h42-d" x1="8.25" x2="8.25" xlink:href="#h42-a" y1="16390.52" y2="16420.29"/><linearGradient id="h42-e" x1="19.89" x2="19.89" xlink:href="#h42-a" y1="16390.52" y2="16420.9"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 16425.33)" gradientUnits="userSpaceOnUse" id="h42-b" x2="28.57" y1="16390.47" y2="16390.47"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h42-i" x1="82.77" x2="137.23" y1="102.35" y2="102.35"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h42-j" x1="110" x2="110" xlink:href="#h42-b" y1="151.14" y2="83.53"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h42-c" x1="110" x2="110" y1="168.85" y2="159.53"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h42-k" x1="103.71" x2="116.29" xlink:href="#h42-b" y1="160.56" y2="160.56"/><linearGradient id="h42-l" x1="110" x2="110" xlink:href="#h42-c" y1="160.47" y2="167.9"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h42-m" x1="82.77" x2="137.23" y1="100.24" y2="100.24"><stop offset="0" stop-color="gray"/><stop offset=".2" stop-color="#4b4b4b"/><stop offset=".8" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h42-o" x1="83.55" x2="136.45" xlink:href="#h42-b" y1="104.91" y2="104.91"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h42-p" x1="135" x2="135" xlink:href="#h42-a" y1="158.86" y2="165.14"/><linearGradient gradientTransform="rotate(180 110 132)" id="h42-q" x1="135" x2="135" xlink:href="#h42-a" y1="158.86" y2="165.14"/><radialGradient cx=".5" cy="1" id="h42-f" r="1"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></radialGradient><radialGradient cy=".2" id="h42-n" r="1"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset=".6" stop-color="#4b4b4b"/><stop offset="1" stop-color="gray"/></radialGradient><symbol id="h42-h" viewBox="0 0 28.57 41.33"><path d="M14.29 5.8a2.66 2.66 0 1 0-2.67-2.66A2.67 2.67 0 0 0 14.3 5.8Z" fill="none" stroke="url(#h42-a)" stroke-width=".95"/><path d="M2.64 34.64 13.85 5.2" fill="none" stroke="url(#h42-d)" stroke-width=".95"/><path d="M13.85 5.2a.46.46 0 0 1 .87 0l11.21 29.44" fill="none" stroke="url(#h42-e)" stroke-width=".95"/><path d="m0 34.09 14.29 2.48 14.28-2.48-.76-.95H.76Z" fill="url(#h42-b)"/><path d="M0 34.09a17.72 17.72 0 0 0 28.57 0Z" fill="url(#h42-f)"/></symbol><filter id="h42-g"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h42-g)"><use height="41.33" transform="matrix(-1 0 0 1 99.29 98.86)" width="28.57" xlink:href="#h42-h"/><use height="41.33" transform="translate(120.71 98.86)" width="28.57" xlink:href="#h42-h"/><path d="M137.23 162 110 163.36 82.77 162l.78-.95 26.45-1.12 26.45 1.12Z" fill="url(#h42-i)"/><path d="M107.94 98.67c2.86-2.72-.94-4.8-.94-7.73 0-2.73 1.71-3.37 3-6.2 1.43 3.13 3 3.49 3 6.2 0 3-3.82 4.99-.94 7.73a7.47 7.47 0 0 1-4.12 0Zm1.15 4.86c0 10.9-2.62 15.24-2.62 24.08 0 8.35 2.46 12.95 2.62 23.03h1.82c.16-10.08 2.62-14.68 2.62-23.03 0-8.84-2.63-13.18-2.63-24.09" fill="url(#h42-f)" stroke="url(#h42-n)"/><path d="M111.56 104.24h-3.11l.11 1.48 1.03-.69h.83l1.02.69Z"/><path d="M138.63 98.91c-.7-.86-2.12.9-3.63.9-6.06 0-7.74-4.66-14.29-4.66S114.5 98.2 110 98.2s-4.17-3.05-10.71-3.05S91.06 99.8 85 99.8c-1.51 0-2.92-1.76-3.63-.9s2.04 2.74 6.98 2.74 6.11-1.25 9.72-1.25c5.01 0 5.64 2.98 5.64 4.07l6.29-.4 6.3.4c0-1.1.62-4.07 5.63-4.07 3.61 0 4.79 1.25 9.72 1.25s7.68-1.88 6.98-2.74Z" fill="url(#h42-c)"/><path d="M114.48 102.4h-8.96l-1.81 2.07h12.58Z" fill="url(#h42-k)"/><path d="M104.54 103.53c-.33-1.48-1.61-4.08-6.47-4.08-3.56 0-4.75 1.25-9.72 1.25-.58 0-1.1-.02-1.6-.07 5.06-.76 6.94-4.53 12.54-4.53 6.24 0 5.97 3.05 10.71 3.05 4.28 0 5.39-3.05 10.72-3.05a12.58 12.58 0 0 1 6.96 2.27 15.04 15.04 0 0 0 5.57 2.26c-.49.05-1.02.07-1.6.07-4.72 0-5.86-1.25-9.72-1.25-4.86 0-6.14 2.6-6.47 4.07Z" fill="url(#h42-l)"/><path d="M85 165.53h50l2.23-3.53H82.77Z" fill="url(#h42-m)"/><path d="M110 159.28a4.9 4.9 0 1 0-4.9-4.9 4.9 4.9 0 0 0 4.9 4.9Z" fill="url(#h42-n)"/><path d="M114.05 157.13a12.22 12.22 0 0 1-8.1 0c-8.91 2.79-22.4 3.92-22.4 3.92h52.9s-13.49-1.13-22.4-3.92Z" fill="url(#h42-o)"/><path d="M135 99.34a2.67 2.67 0 0 1 2.66 2.66m-5.33 0a2.66 2.66 0 0 0 2.67 2.67" fill="none" stroke="url(#h42-p)" stroke-width=".95"/><path d="M85 104.67a2.66 2.66 0 0 0 2.67-2.67m-5.33 0A2.67 2.67 0 0 1 85 99.34" fill="none" stroke="url(#h42-q)" stroke-width=".95"/></g>'
					)
				)
			);
	}

	function hardware_43() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Pulleys',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16391.88)" gradientUnits="userSpaceOnUse" id="h43-a" x1="3.64" x2="0.96" y1="16389.92" y2="16385.27"><stop offset="0" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 50.03, 16617)" gradientUnits="userSpaceOnUse" id="h43-b" x1="-37.53" x2="-37.53" y1="16571" y2="16617"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 50.03, 16617)" gradientUnits="userSpaceOnUse" id="h43-c" x1="-51.86" x2="-23.2" y1="16585.5" y2="16614.17"><stop offset="0.02" stop-color="#fff"/><stop offset="0.75" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 50.03, 16617)" gradientUnits="userSpaceOnUse" id="h43-d" x1="-25.03" x2="-50.03" y1="16595" y2="16595"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, -1, 0, 16415)" id="h43-e" x1="15.5" x2="15.5" xlink:href="#h43-b" y1="16384.5" y2="16414.5"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h43-f" x1="15.5" x2="15.5" xlink:href="#h43-b" y1="0" y2="31"/><linearGradient gradientTransform="matrix(47.39, 0, 0, -47.39, -375547.82, 403411.4)" id="h43-g" x1="7924.9" x2="7924.9" xlink:href="#h43-b" y1="8511.96" y2="8512.45"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h43-h" x1="15.5" x2="15.5" xlink:href="#h43-b" y1="3.24" y2="27.76"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h43-i" x1="15.5" x2="15.5" xlink:href="#h43-b" y1="8.39" y2="22.61"/><clipPath id="h43-j"><path d="M160,72v75a50,50,0,0,1-100,0V72Z" fill="none"/></clipPath><filter id="h43-k" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h43-m" viewBox="0 0 5 7.88"><path d="M.73,0,4.27,3.94a3,3,0,0,1,0,3.94L.73,3.94A3,3,0,0,1,.73,0Z" fill="url(#h43-a)"/></symbol><symbol id="h43-l" viewBox="0 0 5 63.88"><use height="7.88" transform="translate(0 36)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 32)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 28)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 24)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 20)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 16)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 12)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 8)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 4)" width="5" xlink:href="#h43-m"/><use height="7.88" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 40)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 44)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 48)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 52)" width="5" xlink:href="#h43-m"/><use height="7.88" transform="translate(0 56)" width="5" xlink:href="#h43-m"/></symbol><symbol id="h43-cn" viewBox="0 0 31 31"><path d="M15.5,30.5a15,15,0,1,0-15-15A15,15,0,0,0,15.5,30.5Z" fill="url(#h43-e)" stroke="url(#h43-f)"/><path d="M15.5,27.26A11.76,11.76,0,1,0,3.74,15.5,11.75,11.75,0,0,0,15.5,27.26Z" fill="url(#h43-g)" stroke="url(#h43-h)"/><path d="M15.5,22.11A6.61,6.61,0,1,0,8.89,15.5,6.61,6.61,0,0,0,15.5,22.11Z" stroke="url(#h43-i)"/></symbol><symbol id="h43-co" viewBox="0 0 25 46"><path d="M9.5,28V43a3,3,0,0,0,6,0V28L25,17V0H0V17Z" fill="url(#h43-b)"/><path d="M24,0V16L14.5,27V43a2,2,0,0,1-4,0V27L1,16V0Z" fill="url(#h43-c)"/><path d="M0,17l1-1,9.5,11-1,1Zm25,0-1-1L14.5,27l1,1Z" fill="url(#h43-d)"/></symbol></defs><g clip-path="url(#h43-j)"><g filter="url(#h43-k)"><use height="63.88" transform="translate(132.51 39.28)" width="5" xlink:href="#h43-l"/><use height="63.88" transform="translate(132.51 99.28)" width="5" xlink:href="#h43-l"/><use height="63.88" transform="translate(107.5 100.84)" width="5" xlink:href="#h43-l"/><use height="63.88" transform="matrix(-1, 0, 0, 1, 87.49, 100.84)" width="5" xlink:href="#h43-l"/><use height="63.88" transform="matrix(-1, 0, 0, 1, 87.49, 160.84)" width="5" xlink:href="#h43-l"/><use height="31" transform="translate(81.99 86.5)" width="31" xlink:href="#h43-cn"/><use height="46" transform="translate(84.99 59)" width="25" xlink:href="#h43-co"/><use height="31" transform="translate(106.99 146.5)" width="31" xlink:href="#h43-cn"/><use height="46" transform="translate(135.01 205) rotate(180)" width="25" xlink:href="#h43-co"/></g></g>'
					)
				)
			);
	}

	function hardware_44() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Gears',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient id="h44-a" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h44-c" x1="0" x2="0" xlink:href="#h44-a" y1="1" y2="0"/><linearGradient id="h44-b" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h44-g" x1="0" x2="0" xlink:href="#h44-b" y1="1" y2="0"/><linearGradient id="h44-f" x1="0" x2="0" xlink:href="#h44-b" y1=".2" y2=".8"/><linearGradient id="h44-i" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><symbol id="h44-h" viewBox="0 0 5.61 5.74"><path d="M3.06.92 3.7 0l1.91 4.97-.7.77L3.06.92z" fill="url(#h44-a)"/><path d="M2.54.92 1.91 0 0 4.97l.7.77L2.54.92z" fill="url(#h44-c)"/></symbol><symbol id="h44-d" viewBox="0 0 6.48 5.63"><path d="m5.95 0 .53.99-2.4 4.64-.58-.91L5.95 0z" fill="url(#h44-a)"/><path d="M.53 0 0 .99l2.4 4.64.57-.91L.53 0z" fill="url(#h44-c)"/></symbol><symbol id="h44-j" viewBox="0 0 34.29 26.68"><use height="5.63" transform="translate(27.82)" width="6.48" xlink:href="#h44-d"/><use height="5.63" transform="rotate(-15 17.15 -74.22)" width="6.48" xlink:href="#h44-d"/><use height="5.63" transform="rotate(-30 17.15 -20.48)" width="6.48" xlink:href="#h44-d"/><use height="5.63" transform="rotate(-45 17.15 -2.15)" width="6.48" xlink:href="#h44-d"/><use height="5.63" transform="rotate(-60 17.15 7.34)" width="6.48" xlink:href="#h44-d"/><use height="5.63" transform="rotate(-75 17.15 13.3)" width="6.48" xlink:href="#h44-d"/></symbol><filter id="h44-e"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h44-e)"><path d="m112.45 91.5-1.88-4.9h-1.14l-1.88 4.9-.67.18-4.07-3.3-1 .58.83 5.17-.5.5-5.17-.83-.58 1 3.3 4.07-.17.67-4.9 1.88v1.15l4.9 1.87.18.67-3.3 4.07.57 1 5.18-.82.5.49-.83 5.17 1 .58 4.06-3.3.68.17 1.87 4.9h1.15l1.88-4.9.67-.18 4.07 3.3 1-.57-.83-5.18.49-.49 5.18.82.57-1-3.3-4.06.18-.67 4.9-1.88v-1.15l-4.9-1.88-.18-.67 3.3-4.07-.58-1-5.17.83-.5-.49.83-5.18-1-.57-4.07 3.3Zm2.19 10.49a4.64 4.64 0 1 1-4.64-4.64 4.64 4.64 0 0 1 4.64 4.64Z" fill="url(#h44-f)" stroke="url(#h44-g)" stroke-width=".9"/><use height="5.74" transform="translate(107.2 86.15)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(-30 217.15 -141.12)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(-60 131 -33.92)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(-90 99.48 5.32)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(-120 81.27 27.97)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(-150 67.94 44.55)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(180 56.4 58.92)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(150 44.86 73.28)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(120 31.54 89.86)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(90 13.33 112.52)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(60 -18.2 151.76)" width="5.61" xlink:href="#h44-h"/><use height="5.74" transform="rotate(30 -104.35 258.95)" width="5.61" xlink:href="#h44-h"/><path d="m140.64 152.83.29-2.16-4.68-2.42v-1.11l4.67-2.42-.27-2.15-5.15-1.13-.29-1.08 3.9-3.54-.84-2.01-5.25.24-.57-.96 2.84-4.43-1.31-1.73-5.02 1.6-.8-.79 1.6-5.01-1.72-1.33-4.43 2.84-.97-.55.25-5.26-2-.84-3.56 3.9-1.07-.3-1.13-5.13-2.15-.3-2.42 4.68h-1.12l-2.41-4.67-2.16.28-1.13 5.14-1.07.3-3.55-3.9-2 .83.24 5.26-.97.57-4.43-2.84-1.72 1.31 1.6 5.02-.8.8-5-1.6-1.34 1.72 2.84 4.43-.55.97-5.26-.25-.83 2 3.89 3.56-.29 1.07-5.14 1.13-.29 2.15 4.68 2.42v1.11l-4.67 2.42.28 2.16 5.14 1.12.3 1.08-3.9 3.54.83 2.01 5.26-.24.56.96-2.84 4.43 1.32 1.73 5.02-1.6.79.8-1.6 5 1.72 1.33 4.43-2.84.97.56-.24 5.25 2 .84 3.55-3.89 1.08.28 1.12 5.15 2.16.28 2.42-4.67h1.11l2.42 4.67 2.15-.28 1.13-5.14 1.07-.3 3.55 3.9 2-.83-.23-5.26.96-.56 4.43 2.84 1.73-1.32-1.6-5.02.79-.79 5.01 1.6 1.33-1.72-2.84-4.44.55-.96 5.26.24.84-2-3.9-3.55.29-1.08Zm-22.07 3.43h-17.14v-17.13h17.14Z" fill="url(#h44-f)" stroke="url(#h44-g)" stroke-width=".9"/><path d="M108.56 135.14a12.89 12.89 0 1 0 14.25 11.36 12.89 12.89 0 0 0-14.25-11.36Zm2.26 20.01a7.25 7.25 0 1 1 6.39-8.02 7.25 7.25 0 0 1-6.4 8.02Z" fill="url(#h44-i)"/><use height="26.68" transform="translate(78.95 116.27)" width="34.29" xlink:href="#h44-j"/><use height="26.68" transform="rotate(-90 128.66 50.09)" width="34.29" xlink:href="#h44-j"/><use height="26.68" transform="rotate(180 70.53 89.56)" width="34.29" xlink:href="#h44-j"/><use height="26.68" transform="rotate(90 12.4 129.03)" width="34.29" xlink:href="#h44-j"/><circle cx="110" cy="147.94" fill="none" r="7.25" stroke="url(#h44-a)"/><circle cx="110" cy="101.99" fill="none" r="4.64" stroke="url(#h44-g)"/></g>'
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