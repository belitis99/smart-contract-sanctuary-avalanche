// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs19 is IHardwareSVGs, ICategories {
	function hardware_73() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Four Wheels',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="translate(18.63 -18.63)" gradientUnits="userSpaceOnUse" id="h73-a" x1="-2.62" x2="3.33" y1="40.6" y2="34.65"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h73-b" x1="-12.9" x2="13.66" xlink:href="#h73-a" y1="50.88" y2="24.32"/><linearGradient gradientTransform="translate(18.63 -18.63)" gradientUnits="userSpaceOnUse" id="h73-c" x1="0.36" x2="0.36" y1="33.37" y2="41.87"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h73-d" x1="0.36" x2="0.36" xlink:href="#h73-c" y1="18.63" y2="56.61"/><linearGradient id="h73-e" x1="0.36" x2="0.36" xlink:href="#h73-a" y1="35.12" y2="40.13"/><linearGradient id="h73-f" x1="0.36" x2="0.36" xlink:href="#h73-a" y1="35.13" y2="40.12"/><linearGradient id="h73-g" x1="0.36" x2="0.36" xlink:href="#h73-a" y1="21.92" y2="53.32"/><linearGradient gradientUnits="userSpaceOnUse" id="h73-h" x1="-0.16" x2="4.29" y1="6.05" y2="6.05"><stop offset="0" stop-color="gray"/><stop offset="0.24" stop-color="#4b4b4b"/><stop offset="0.68" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h73-i" x2="4.35" y1="10.9" y2="10.9"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><filter id="h73-j" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><symbol id="h73-m" viewBox="0 0 4.35 12.1"><path d="M4.348,12.1H0v-.8l2.1-.235,2.244.235ZM4.009,0,3.4,10.707H.951L.337,0Z" fill="url(#h73-h)"/><path d="M4.348,11.3,3.4,10.5H.951L0,11.3v0Z" fill="url(#h73-i)"/></symbol><symbol id="h73-l" viewBox="0 0 4.35 28.93"><use height="12.1" transform="translate(0 16.83)" width="4.35" xlink:href="#h73-m"/><use height="12.1" transform="matrix(1, 0, 0, -1, 0, 12.1)" width="4.35" xlink:href="#h73-m"/></symbol><symbol id="h73-k" viewBox="0 0 37.98 37.98"><use height="28.93" transform="translate(16.77 3.54) scale(1.02 1.07)" width="4.35" xlink:href="#h73-l"/><use height="28.93" transform="translate(6.5 9.63) rotate(-45) scale(1.02 1.07)" width="4.35" xlink:href="#h73-l"/><use height="28.93" transform="matrix(0, -1.02, 1.07, 0, 3.54, 21.2)" width="4.35" xlink:href="#h73-l"/><use height="28.93" transform="matrix(-0.72, -0.72, 0.76, -0.76, 9.63, 31.48)" width="4.35" xlink:href="#h73-l"/><path d="M19,22.2A3.21,3.21,0,1,1,22.2,19,3.21,3.21,0,0,1,19,22.2Z" fill="none" stroke="url(#h73-a)" stroke-width="2"/><path d="M19,36A17,17,0,1,1,36,19,17,17,0,0,1,19,36Z" fill="none" stroke="url(#h73-b)" stroke-width="3.57"/><path d="M19,23a4,4,0,1,1,4-4A4,4,0,0,1,19,23Z" fill="none" stroke="url(#h73-c)" stroke-width="0.5"/><path d="M19,37.72A18.74,18.74,0,1,1,37.72,19,18.76,18.76,0,0,1,19,37.72Z" fill="none" stroke="url(#h73-d)" stroke-width="0.5"/><circle cx="18.99" cy="18.99" fill="none" r="2.25" stroke="url(#h73-e)" stroke-width="0.5"/><circle cx="18.99" cy="18.99" fill="none" r="2.25" stroke="url(#h73-f)" stroke-width="0.5"/><circle cx="18.99" cy="18.99" fill="none" r="15.45" stroke="url(#h73-g)" stroke-width="0.5"/><path d="M18.19,2a.73.73,0,1,1,.73.73A.73.73,0,0,1,18.19,2Zm.87,34.8a.72.72,0,0,0,.72-.72.73.73,0,0,0-.72-.73.73.73,0,0,0-.73.73A.73.73,0,0,0,19.06,36.75ZM6.89,7.72a.73.73,0,1,0,0-1.46.73.73,0,0,0,0,1.46ZM2,19.78a.73.73,0,0,0,.73-.72.73.73,0,0,0-1.46,0A.73.73,0,0,0,2,19.78Zm5,12a.73.73,0,0,0,.73-.72.73.73,0,1,0-1.46,0A.73.73,0,0,0,7,31.81ZM31.81,7a.73.73,0,0,0-.72-.73.73.73,0,0,0,0,1.46A.73.73,0,0,0,31.81,7Zm4.94,12.07a.73.73,0,0,0-.72-.73.73.73,0,0,0-.73.73.73.73,0,0,0,.73.72A.72.72,0,0,0,36.75,19.06Zm-5,12a.73.73,0,0,0-.72-.73.73.73,0,0,0-.73.73.73.73,0,0,0,.73.72A.72.72,0,0,0,31.71,31.09Z"/></symbol></defs><g filter="url(#h73-j)"><use height="37.98" transform="translate(91.01 83.01)" width="37.98" xlink:href="#h73-k"/><use height="37.98" transform="translate(91.01 143.01)" width="37.98" xlink:href="#h73-k"/><use height="37.98" transform="translate(116.01 113.01)" width="37.98" xlink:href="#h73-k"/><use height="37.98" transform="translate(66.01 113.01)" width="37.98" xlink:href="#h73-k"/></g>'
					)
				)
			);
	}

	function hardware_74() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Pear Diamond',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h74-a" x1="13.03" x2="26.03" y1="57.83" y2="77.44"><stop offset="0" stop-color="#4b4b4b"/><stop offset="0.85" stop-color="#fff"/></linearGradient><linearGradient id="h74-b" x1="7.56" x2="7.56" xlink:href="#h74-a" y1="16.09" y2="31.8"/><linearGradient id="h74-c" x1="15.94" x2="15.94" xlink:href="#h74-a" y1="6.89" y2="19.53"/><linearGradient id="h74-d" x1="8.02" x2="8.02" xlink:href="#h74-a" y1="31.74" y2="51.84"/><linearGradient gradientTransform="translate(16534.01 16496.31) rotate(180)" id="h74-e" x1="16528.6" x2="16528.6" xlink:href="#h74-a" y1="16476.78" y2="16454.51"/><linearGradient gradientTransform="translate(16534.01 16496.31) rotate(180)" id="h74-f" x1="16519.5" x2="16519.5" xlink:href="#h74-a" y1="16454.51" y2="16421.7"/><linearGradient id="h74-g" x1="18.73" x2="26.02" xlink:href="#h74-a" y1="74.06" y2="88.86"/><linearGradient gradientTransform="translate(16534.01 16496.31) rotate(180)" id="h74-h" x1="16528.91" x2="16528.91" xlink:href="#h74-a" y1="16454.51" y2="16431.68"/><linearGradient gradientTransform="translate(16534.01 16496.31) rotate(180)" id="h74-i" x1="16526" x2="16526" xlink:href="#h74-a" y1="16454.51" y2="16454.51"/><linearGradient gradientTransform="translate(16534.01 16496.31) rotate(180)" id="h74-j" x1="16520.38" x2="16520.38" xlink:href="#h74-a" y1="16493.76" y2="16487.72"/><linearGradient gradientTransform="translate(16534.01 16496.31) rotate(180)" id="h74-k" x1="16510.95" x2="16510.95" xlink:href="#h74-a" y1="16496.31" y2="16489.42"/><linearGradient id="h74-l" x1="6.71" x2="19.51" xlink:href="#h74-a" y1="6.16" y2="19.57"/><filter id="h74-m" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient id="h74-n" x1="110" x2="110" xlink:href="#h74-a" y1="94.31" y2="148.8"/><linearGradient gradientTransform="translate(340.88 286.88) rotate(180)" id="h74-o" x1="230.88" x2="230.88" xlink:href="#h74-a" y1="128.49" y2="107.25"/><linearGradient gradientTransform="translate(340.88 286.88) rotate(180)" id="h74-p" x1="230.88" x2="230.88" xlink:href="#h74-a" y1="196.68" y2="186.37"/><linearGradient id="h74-q" x1="110.95" x2="109.79" xlink:href="#h74-a" y1="179.82" y2="161.55"/><linearGradient gradientTransform="matrix(1, 0, 0, -1, -120.88, 286.88)" id="h74-r" x1="230.88" x2="230.88" xlink:href="#h74-a" y1="196.68" y2="186.37"/><symbol id="h74-s" viewBox="0 0 29.13 89.43"><polygon fill="url(#h74-a)" points="16.04 51.84 8.3 64.62 19.1 80.84 29.13 68.19 16.04 51.84"/><polygon fill="url(#h74-b)" points="2.75 16.09 0 31.8 10.81 31.74 15.12 16.32 2.75 16.09"/><path d="M8,8.59l-5.26,7.5,4.88,3.44,7.49-3.21,14-6L19.25,6.89Z" fill="url(#h74-c)"/><polygon fill="url(#h74-d)" points="10.81 31.74 0 31.8 1.91 45.8 16.04 51.84 10.81 31.74"/><polygon fill="url(#h74-e)" points="8.01 41.8 10.81 31.74 7.63 19.53 0 31.8 8.01 41.8 8.01 41.8"/><polygon fill="url(#h74-f)" points="16.04 51.84 8.01 41.8 7.05 51.84 8.3 64.62 21.97 74.61 16.04 51.84"/><polygon fill="url(#h74-g)" points="19.1 80.84 29.13 89.43 21.97 74.61 19.1 80.84"/><polygon fill="url(#h74-h)" points="8.01 41.8 1.91 45.8 8.3 64.62 8.01 41.8 8.01 41.8"/><path d="M8,41.8Z" fill="url(#h74-i)"/><polygon fill="url(#h74-j)" points="16.98 2.54 8.01 8.59 19.25 6.89 16.98 2.54"/><polygon fill="url(#h74-k)" points="29.13 0 16.98 2.54 19.25 6.89 29.13 0"/><polygon fill="url(#h74-l)" points="15.12 16.32 15.12 16.32 19.25 6.89 8.01 8.59 7.63 19.53 15.12 16.32"/></symbol></defs><g filter="url(#h74-m)"><polygon fill="url(#h74-n)" points="110 179.63 80.87 121.94 110 90.2 139.13 121.94 110 179.63"/><polygon fill="url(#h74-o)" points="110 158.39 102.84 164.81 110 179.63 117.16 164.81 110 158.39"/><polygon fill="url(#h74-p)" points="110 100.5 119.89 97.09 110 90.2 100.11 97.09 110 100.5"/><use height="89.43" transform="translate(80.87 90.2)" width="29.13" xlink:href="#h74-s"/><use height="89.43" transform="matrix(-1, 0, 0, 1, 139.13, 90.2)" width="29.13" xlink:href="#h74-s"/><polygon fill="url(#h74-q)" points="110 158.39 117.16 164.81 110 179.63 102.84 164.81 110 158.39"/><polygon fill="url(#h74-r)" points="110 100.5 100.11 97.09 110 90.2 119.89 97.09 110 100.5"/></g>'
					)
				)
			);
	}

	function hardware_75() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Maple Leaf',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h75-a" x1="26.36" x2="30.62" y1="44.28" y2="70.19"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h75-b" x1="17" x2="18.27" xlink:href="#h75-a" y1="21.01" y2="57.05"/><linearGradient id="h75-c" x1="18.87" x2="21.63" xlink:href="#h75-a" y1="40.7" y2="65.11"/><linearGradient gradientUnits="userSpaceOnUse" id="h75-d" x1="48.21" x2="14.41" y1="12.9" y2="35.84"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h75-e" x1="15.53" x2="15.53" y1="12.36" y2="47.7"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><radialGradient cx="38.69" cy="5.78" gradientUnits="userSpaceOnUse" id="h75-f" r="58.63"><stop offset="0" stop-color="#fff"/><stop offset="0.32" stop-color="gray"/><stop offset="1" stop-color="#fff"/></radialGradient><linearGradient gradientUnits="userSpaceOnUse" id="h75-g" x1="29.66" x2="29.66" y1="5.52" y2="68.83"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><radialGradient cx="17.86" cy="22.14" gradientUnits="userSpaceOnUse" id="h75-h" r="15.95"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="0.6" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></radialGradient><filter id="h75-i" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><clipPath id="h75-j"><path d="M122,127.87s20-4.27,21.92-3.85c0,0-8.92-3.25-9.28-5.37s6.72-8.14,8.69-9.23c0,0-13,1.94-13.62,1s.78-7.76.94-8c0,0-17,20.15-15.25,14.94l11-27.84s-5.61,4.95-7.94,4S110,80.25,110,80.24s-6.15,12.36-8.47,13.29-7.94-4-7.94-4l11,27.84c1.73,5.21-15.25-14.94-15.25-14.94.16.29,1.54,7.16.94,8s-13.62-1-13.62-1c2,1.09,9,7.11,8.69,9.23S76.08,124,76.08,124C78,123.6,98,127.87,98,127.87c5,2.23-17.06,4.13-17.06,4.13,2.69.68,5.32.77,5.87,2s-7.27,8.15-7.27,8.15c6.15-2.12,7.76-2.16,8.83-1.28s-2.26,6.23-2.26,6.23c6-7.4,9.11-7.88,10.63-6.67,2.12,1.7-.95,8.62-.95,8.62h0c7.22-8.67,11.29-9.28,12.57-7.65s-1.31,16.2-1.31,16.2L110,171l3-13.29s-2.64-14.67-1.36-16.29,5.35-1,12.57,7.65h0s-3.07-6.92-.95-8.62c1.52-1.21,4.59-.73,10.63,6.67,0,0-3.32-5.36-2.26-6.23s2.68-.84,8.83,1.28c0,0-7.82-6.91-7.27-8.15s3.18-1.32,5.87-2C139.06,132,117,130.1,122,127.87Z" fill="none"/></clipPath><radialGradient cx="110" cy="114.81" id="h75-k" r="34.06" xlink:href="#h75-e"/><symbol id="h75-l" viewBox="0 0 35.92 82.61"><path d="M21.71,68.81s.52,13.8,14.21,13.8V49.26Z" fill="url(#h75-a)"/><path d="M2.59,29.18S-4.84,48.85,5.46,61.9c12.35,2.25,30.46-10.14,30.46-10.14C32.19,32.33,2.59,29.18,2.59,29.18Z" fill="url(#h75-b)"/><path d="M5.46,61.9S19,53,35.92,51.76L21.71,68.81h0C6.86,71.43,5.46,61.9,5.46,61.9Z" fill="url(#h75-c)"/><path d="M35.92,0V51.76C26.28,40.18,2.59,29.18,2.59,29.18-1.67.77,35.92,0,35.92,0Z" fill="url(#h75-d)"/></symbol><symbol id="h75-n" viewBox="0 0 40.51 56.26"><path d="M27.85,39.74c3.28,4.25,4.22,9.18-.8,6.87-2.22-1-4.86-2.87-6.6-8.3A17.77,17.77,0,0,0,11,27.6c-7.3-3.28-8.41-3.85-9.52-6.28C0,18.09.34,12.86,1.83,12.86" fill="none" stroke="url(#h75-e)" stroke-miterlimit="10"/><path d="M39.51,34.88V56.26l-4.66-4.77A23.93,23.93,0,0,0,37,41.65c-.5-10.73-2.21-15-6.86-16.88-5.43-2.25-10.57,1.71-6.55,5C26.27,32.45,25,35,28.4,39.39s3.82,9.15-1.19,6.84c-2.22-1-4.38-2.22-6.13-7.65a19.39,19.39,0,0,0-9.83-11.29C4,24,2.9,23.59,1.79,21.16c-1.47-3.23-1.49-8.82,0-8.82.65,0,3,2.11,4.13,3.17a51.46,51.46,0,0,0,8,5.67c5.14,2.89,6.3,3.68,7.93,2.91,4.39-2.08,6.57-2.34,10.79-.47C38.82,26.74,39.51,34.88,39.51,34.88Z" fill="url(#h75-f)"/><path d="M40.51,32.55c0-16.32-1-32.55-1-32.55L39,.62s-.06,8.1-.06,11.72-.79,15.3-.79,15.3-3.66-5.28-10.27-5.28c-3.55,0-6.25,2.51-9.07,2.3,0,1.44.86,2.19,2.33,2.5-.93-2.25,5.68-5.13,9.61-3.5,4.65,1.88,7.56,5.26,7.22,17.92,0,2.79-.59,6.36-.21,9.33a16.31,16.31,0,0,0,1.75,5.35S40.51,48.87,40.51,32.55Z" fill="url(#h75-g)"/><path d="M23.54,31.93c0,2.28-3.51,4.06-4.46,2.53-1.58-2.56-5.1-5.43-7-6.75s.4-4.9,2.33-4.9C19.59,22.81,23.54,30.59,23.54,31.93Z" fill="url(#h75-h)"/></symbol></defs><g filter="url(#h75-i)"><g clip-path="url(#h75-j)"><use height="82.61" transform="translate(74.08 80.24)" width="35.92" xlink:href="#h75-l"/><use height="82.61" transform="matrix(-1, 0, 0, 1, 145.92, 80.24)" width="35.92" xlink:href="#h75-l"/><path d="M110,132,95.79,149.05M110,132c-17,1.23-30.46,10.15-30.46,10.15m-2.87-32.73s23.68,11,33.33,22.58V80.24m14.21,68.81L110,132m30.46,10.15S127,133.23,110,132m0-51.76V132c9.65-11.58,33.33-22.58,33.33-22.58" fill="none" stroke="url(#h75-k)" stroke-miterlimit="10"/></g><use height="56.26" transform="translate(70.49 132.67)" width="40.51" xlink:href="#h75-n"/><use height="56.26" transform="matrix(-1, 0, 0, 1, 149.51, 132.67)" width="40.51" xlink:href="#h75-n"/></g>'
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